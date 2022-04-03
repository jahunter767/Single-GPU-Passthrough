#! /bin/bash

# Unload vfio
function unload_vfio {
    for v in ${VFIO_KMODS[*]}; do
        modprobe -r ${v}
    done
} # End-unload_vfio


# Reattach the USB Controller(s)
function reattach_usb_ctrls {
    for uc in ${usb_ctrls[*]}; do
        virsh nodedev-reattach ${uc}
    done
} # End-reattach_usb_ctrls

# Rebind the GPU
function reattach_gpu {
    gpu=()
    kmods=()

    # Parse parameters
    flags="^(-dev|-kmods)$"
    flag=""
    for p in ${@}; do
        if [[ ${p} =~ ${flags} ]]; then
            flag=${p}
        else
            case $flag in
                -dev)
                    gpu+=("${p}")
                ;;
                -kmods)
                    kmods+=("${p}")
                ;;
                *)
                ;;
            esac
        fi
    done

    # Rebind the GPU to the host
    for g in ${gpu[*]}; do
        virsh nodedev-reattach ${g}
    done

    # Reload all GPU drivers
    for k in ${kmods[*]}; do
        modprobe ${k}
    done

    # Rebind EFI-Framebuffer
    echo "efi-framebuffer.0" > /sys/bus/platform/drivers/efi-framebuffer/bind

    # Rebind VTconsoles
    for v in /sys/class/vtconsole/vtcon*; do
        echo 1 > ${v}/bind
    done

    # Start display manager
    systemctl start display-manager.service
} # End-reattach_gpu
