# Single-GPU-Passthrough

This reopsitory was created to share my spin on setting up a virtual machine
for single GPU passthrough. Most of the information here was taken from several
resources I used when coming up with my setup so I won't get into too much of
the basics to keep this short.

## TODO

1. Update readme instructions on how to use the hooks in this repository
2. All the other script improvements scattered around the hook scripts
    (Search "@TODO" to find them). Most improvements right now are to make the
    hooks more dynamic when it comes to enabling/disabling host features.

## Credits

First of I would like to acknowledge the various guides and resources I used
to setup my own system for this:

 - [chironjit's guide](https://github.com/chironjit/single-gpu-passthrough) -
    I found this guide to be particularly thorough in detailing the exact steps
    to setup the virtual machine from the recommended BIOS settings up to the
    final VM.

 - SomeOrdinaryGamers videos(
    [I Almost Lost My Virtual Machines...](https://youtu.be/BUSrdUoedTo?t=204) and
    [Indian Man Beats VALORANT's Shady Anticheat...](https://youtu.be/L1JCCdo1bG4?t=208))-
    The first video is his guide which is pretty thorough and the second video
    has details on additional hypervisor settings to facilitate some anti-cheat
    software some games use.

 - [joeknock90's guide](https://github.com/joeknock90/Single-GPU-Passthrough) -
    Most of the content in this guide is covered in chironjit's but this one
    also has some useful troubleshooting tips

 - [bryansteiner's guide](https://github.com/bryansteiner/gpu-passthrough-tutorial) -
    While this guide doesn't cover single GPU passthrough it did help me
    understand the general theory behind passing through hardware to a VM.
    It also contains some useful hypervisor settings to help improve
    virtualization inside the VM (which might be useful for WSL, WSA or other
    software that relies on some Hyper-V features)

 - [Arch Wiki - PCI_passthrough_via_OVMF](https://wiki.archlinux.org/title/PCI_passthrough_via_OVMF) -
    This also doesn't cover single GPU passthrough but has a lot of useful
    information on hardware passthrough in general and also helped me understand
    the theory behind passing through hardware to a VM. This guide also has a
    lot of tips on how to optimise performance inside the VM. A few of the bash
    snippets on that page were used to create the
    [Show-System-Hardware.sh](./Show-System-Hardware.sh) script in this repo

 - [libvirt - Hooks for specific system management](https://libvirt.org/hooks.html) -
    This was useful in understanding how libvirt runs the scripts and the args
    it passes to them.

 - [Linux Kernel Docs - VFIO - “Virtual Function I/O”](https://www.kernel.org/doc/html/latest/driver-api/vfio.html) -
    This resource goes more in depth on how to use the VFIO module

## Disclaimers

 - The scripts in this repository are provided without any sort of warranty or
    support so run them at your own risk.

 - These scripts were also written with Fedora in mind so they not work as
    expected on other distros, however the guides listed above were written with
    Pop_OS or Ubuntu based distros in mind so the scripts are mostly portable
    though some minor changes might be required.

 - The scripts in the hooks folder will be run as root so take care to verify
    their contents before applying them

## Basic Theory

PCI devices connected to the host machine can be grouped into several different
input–output memory management unit (IOMMU) groups. The linux kernel has a
special module (virtual function input-output - VFIO) that can be used to
isolate each group and expose the interfaces for all the devices in the group
to a virtual machine (VM). Single GPU passthrough utilises this feature to
expose a GPU to a VM of your choosing.

In order for the VFIO module to isolate these devices however there are a few
prerequisites that the devices in the IOMMU group must meet. First, they must
be resettable and secondly they must not be bound to any other kernel modules
when binding them to the VFIO module. Please note however that the module can
only isolate whole IOMMU groups and not individual devices in a given group so
unless you want to passthrough the other devices in the group as well, it is
recommended that you try to change the PCIe slot that your GPU (or other device
you want to pass through) is connected to. The exception to this rule however
are PCI bridge devices which are
[unsupported by the vfio-pci module](https://www.kernel.org/doc/html/latest/driver-api/vfio.html#vfio-usage-example)
and can thus be ignored for our purposes (even if they is not resettable).
While it is possible to apply the ACS patch to the kernel to work around this
limitation, it isn't guaranteed to work for your system and requires a lot more
knowledge to implement and is outside the scope of this guide.

Typically when passing through hardware to a VM, you would isolate the hardware
on boot so the devices wouldn't be accessible to the host OS. This would mean
that in a system with one GPU you wouldn't have any graphical output of any
kind. To that end, there are a few additional steps needed to dynamically
isolate the GPU so it may be used by both the host OS and VM:

1. kill all tasks that are using the GPU (these include the desktop environment
and possibly any audio management services on the host)
2. unbind the GPU from the kernel modules that are currently controlling it
3. bind the GPU to the VFIO modules so they can control and isolate it

At this point the GPU should be isolated from the host and free to be exposed
to the VM. Of course there are also a few other specific steps related to GPU
passthrough in the scripts however those are the major steps (these also work
for other PCIe devices as well).

## Preparations

 1. Enable IOMMU by adding the following kernel args:
    - For systems with AMD CPUs `amd_iommu=on iommu=pt`
    - For systems with Intel CPUs `intel_iommu=on iommu=pt`
    The exact steps will vary based on your distro.
    - For Fedora run: `grubby --update-kernel=ALL --args="<args here>"`
    - For Pop_OS run: `kernelstub --add-options "<args here>"`
    You'll likely need to elevate privileges with sudo here.

 2. Download and run the [Show-System-Hardware.sh](./Show-System-Hardware.sh).
    You might  need to elevate privileges for it to list out the IOMMU groups.
    The main purpose of the script is to give an overview of your system so you
    can identify what hardware you may passthrough. When you run it you should
    see it output your CPU topology

    Figure 1

    ![](./imgs/cpu-topo.png)

    and a list of the IOMMU groups in your system and the devices in them like
    this:

    Figure 2

    ![](./imgs/iommu-group(1).png)

    Figure 3

    ![](./imgs/iommu-group(2).png)

    Figure 4

    ![](./imgs/iommu-group(3).png)

    The code on the left of the device name in the form `XX:XX.X` represents
    the `bus:device:function` numbers of that device in the current domain.
    Going forward I'll refer to that code as the domain id of the device. The
    entries with `[RESET]` beside them indicate what devices are resettable
    and are also conveniently coloured green. You can also see what kernel
    modules control the device and the ones that are actively controling the
    device. The script also conveniently list any USB devices connected to any
    USB controllers and any sata drives connected to any sata controllers in
    the system. These also get coloured green if the USB/SATA controller
    they're attached to is resettable. Lastly this script also shows what
    display ports the GPU has and which ones are in use (they also get coloured
    green if the GPU is resettable). Knowing what ports your GPU has is
    particularly important for those attempting this on a laptop. If the dGPU
    in your laptop has no ports then GPU passthrough is unlikely to work for
    you at this point in time (some people have had some success however the
    GPU won't be able to run any graphical workloads/provide any graphical
    output).

    For this specific example we can see I can passthrough my GPU (group 15)
    without needing to isolate and passthrough any additional devices. Not all
    the other devices are listed as resettable however they are exposed as
    additional functions of the main device (you can tell by the fact that the
    domain ids of the devices are all the same except for the function number
    (this number goes from 0 to 7)). I could also passthrough the USB controller
    in group 18. The devices in group 14 may also be good candidates for
    passthrough howerver my boot drive is actually attached to the SATA
    controller.

 3. Once you've figured out what you can and can't passthrough, install libvirt,
    qemu-kvm, libvirt-daemon-kvm, libvirt-daemon-driver-qemu, virsh and virtual
    machine manager

 4. Create a normal VM with Virtual Machine Manager and install the relevant
    drivers inside the VM.
    ([Here's a link to virtio drivers for Windows](https://fedorapeople.org/groups/virt/virtio-win/direct-downloads/stable-virtio/virtio-win.iso)).
    When creating the VM set the BIOS to be a UEFI as pci passthrough will not
    work with a VM running a legacy BIOS.

 5. Download the scripts inside the [hooks folder here](./hooks) and copy them
    into /etc/libvirt/hooks. These scripts are based on the scripts in other
    guides however I created a default folder containing scripts that define
    functions you can reuse for several VMs as the principle is mostly the same
    for each VM you want to passthrough hardware to. There are also sample
    scripts in the `win10` and `win10-gpu` you can use as an example of what
    your configuration will look like.

 6. Edit the `qemu.conf` file in the `qemu.d` folder to include a variable name
    per device you want to passthrough the list of domain ids associated with
    each device in a similar fashion to the devices in the file (ie. prefixed
    by `pci_0000_` and with the special characters replaced with underscores).

 7. Create a folder inside the `qemu.d` folder with the same name as your VM
    then create the folders `prepare`, `prepare/begin/`, `release` and
    `release/end` and the files `vm.conf`, `prepare/begin/start.sh` and
    `release/end/stop.sh`

 8. Update `vm.conf` in a similar fashion to the examples in the repo
    [here](./hooks/qemu.d/win10/vm.conf) and
    [here](./hooks/qemu.d/win10-gpu/vm.conf).
    This file essentially serves as a configuration file for your VM where you
    can assign more memorable names to specific features you intend to enable
    on the host or hardware you intend to passthrough to the vm etc.

 9. Add the snippet below to the `start.sh` and `stop.sh` files you made earlier

    ```
    #! /bin/bash

    # Helpful to read output when debugging
    set -x

    HOOKTYPE_BASEDIR="${0%.d/**}.d"
    GUEST_NAME="${1}"
    HOOK_NAME="${2}"
    STATE_NAME="${3}"
    HOOKPATH="${HOOKTYPE_BASEDIR}/default/${HOOK_NAME}/${STATE_NAME}"

    # Loads preset variables
    source "${HOOKTYPE_BASEDIR}/${GUEST_NAME}/vm.conf"

    # Loads default functions
    if [ -f "$HOOKPATH" ] && [ -s "$HOOKPATH"] && [ -x "$HOOKPATH" ]; then
        source "$HOOKPATH"
    elif [ -d "$HOOKPATH" ]; then
        while read file; do
            # check for null string
            if [ ! -z "$file" ]; then
                source "$file"
            fi
        done <<< "$(find -L "$HOOKPATH" -maxdepth 1 -type f -print;)"
    fi
    ```

    This snippet essentially loads in the functions in the scripts in the
    `default` folder and the variables you created in `vm.conf` for the current
    VM. At this point you can call the relevant functions using the variables
    you created in `vm.conf` as the arguments.

    Note: The order you call the functions in the start and stop scripts is
    important. For the start script you'll need to call the detach functions
    before loading the VFIO modules. For the stop script, you'll need to unload
    the VFIO modules before the reattach functions. As for the other functions
    the order isn't as important. After completing the scripts remember to make
    start.sh, stop.sh and default executable.

 10. Edit the VM configuration to include the pci devices you plan to
    passthrough

    At this point the hardware should be passed through successfully
    if everything was configured properly. There will be a 12+ second delay
    before any graphical output is displayed so keep that in mind. You can
    adjust this value if your VM does not start consistently when passing
    through your GPU. If the VM fails to start and your host login screen
    reloads or you system appears to hang on a black screen then you can
    uncomment these 2 lines (lines 21 and 22)

    ```
    #echo "--------------NEXT--------------${file}" >> "/home/dump.txt"
    #eval \"$file\" "$@" &>> "/home/dump.txt"
    ```

    and comment out this line (line 23)

    ```
    eval \"$file\" "$@"
    ```

    in `hooks/default` and try starting the VM again then check the file it
    creates `/home/dump.txt` to identify if the scripts are failing. You can
    also change the file those 2 lines output to (Note: The file will be created
    as root unless you create it yourself as the hooks are run as root). If
    there  are no errors in the scripts then you can check the logs for the VM
    at `/var/log/libvirt/qemu/<vm-name>.log` (privilege escalation is required
    to read them). It might also be worth checking the message in the kernel
    ring buffer by running `dmesg`.

## Potential Pitfalls

 - The VM will fail to start if the VM is still configured to use a virtual
    display or other virtual devices that rely on having a desktop environment
    running

 - Some AMD GPU's before their Navi architecture have a reset bug in their
    hardware that require extra drivers to facilitate rebinding them to the
    host OS after stopping the VM

 - Updating your BIOS may change the domain ids for each device causing the VM
    to fail to start. Updating the BIOS may also break passthrough support if
    the BIOS is buggy so it is recommended that you refrain from updating your
    BIOS unless absolutely necessary

 - Most scripts simply unload the kernel modules for the PCI device (eg. a GPU)
    when unbinding it, however for those with multiple devices that use the
    same kernel module (eg. two Nvidia GPU's) in their system interested in
    dynamically passing through one of them at a time you'll need to modify
    the scripts to unbind the device from the module without completely
    unloading the module.
