#! /bin/bash

# Passthrough a GPU
function detach_gpu {
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

    # Stop display manager
    systemctl stop display-manager.service

    # Unbind VTconsoles
    for v in /sys/class/vtconsole/vtcon*; do
        echo 0 > ${v}/bind
    done

    # Unbind EFI-Framebuffer
    echo "efi-framebuffer.0" > /sys/bus/platform/drivers/efi-framebuffer/unbind

    # Avoid a Race condition by waiting 2 seconds. This can be calibrated
    # to be shorter or longer if required for your system
    sleep 12

    # Unload all GPU drivers
    for k in ${kmods[*]}; do
        modprobe -r ${k}
    done

    # Unbind the GPU to be used in the vm
    for g in ${gpu[*]}; do
        virsh nodedev-detach ${g}
    done
} # End-detach_gpu

# Passthrough a USB Controller(s)
function detach_usb_ctrls {
    for uc in ${@}; do
        virsh nodedev-detach ${uc}
    done
} # End-detach_usb_ctrls

# Load vfio
function load_vfio {
    for v in ${VFIO_KMODS[*]}; do
        modprobe ${v}
    done
} # End-load_vfio
