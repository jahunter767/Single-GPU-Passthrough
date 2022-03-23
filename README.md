# Single-GPU-Passthrough

This reopsitory was created to share my spin on setting up a virtual machine
for single GPU passthrough. Most of the information here was taken from several resources I used when coming up with my setup so I won't get into too
much of the basics to keep this short.

## Credits

First of I would like to acknowledge the various guides and resources I used
to setup my own system for this:
1. [chironjit's guide](https://github.com/chironjit/single-gpu-passthrough) -
    I found this guide to be particularly thorough in detailing the exact steps
    to setup the virtual machine from the recommended BIOS settings up to the
    final VM.

2. SomeOrdinaryGamers videos(
    [I Almost Lost My Virtual Machines...](https://youtu.be/BUSrdUoedTo?t=204) and
    [Indian Man Beats VALORANT's Shady Anticheat...](https://youtu.be/L1JCCdo1bG4?t=208))-
    The first video is his guide which is pretty thorough and the second video
    has details on additional hypervisor settings to facilitate some anti-cheat
    software some games use.

3. [joeknock90's guide](https://github.com/joeknock90/Single-GPU-Passthrough) -
    Most of the content in this guide is covered in chironjit's but this one
    also has some useful troubleshooting tips

4. [bryansteiner's guide](https://github.com/bryansteiner/gpu-passthrough-tutorial) -
    While this guide doesn't cover single GPU passthrough it did help me
    understand the general theory behind passing through hardware to a VM.
    It also contains some useful hypervisor settings to help improve
    virtualization inside the VM (which might be useful for WSL, WSA or other
    software that relies on some Hyper-V features)

5. [Arch Wiki - PCI_passthrough_via_OVMF](https://wiki.archlinux.org/title/PCI_passthrough_via_OVMF) -
    This also doesn't cover single GPU passthrough but has a lot of useful
    information on hardware passthrough in general and also helped me understand
    the theory behind passing through hardware to a VM. This guide also has a
    lot of tips on how to optimise performance inside the VM.

## Basic Theory

## Preparations

## Potential Pitfalls

