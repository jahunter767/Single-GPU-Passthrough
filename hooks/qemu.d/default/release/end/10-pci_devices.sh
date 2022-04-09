#! /bin/bash

function unload_vfio {
    # @TODO: Check if whether the modules were loaded before starting the VM
    #        is stored and don't unload the the ones that weren't already loaded
    #        Might also need to consider checking for other running VM's that
    #        may currently be using the modules
    #        Potential file to check:
    #        ${TMP_CONFIG_PATH}/state/pci-devs/existing_modules.val
    #modprobe -qr "${VFIO_KMODS[@]}"
    echo "modprobe -qr ${VFIO_KMODS[@]}"
} # End-unload_vfio

function bind_pci_devices {
    declare -a unbind_stack

    function detach {
        local device=$(basename "$(realpath "${1}")")
        local orig_driver="$(cat ${TMP_CONFIG_PATH}/state/pci-devs/${device}/driver.val)"
        local driver_path="/sys/bus/pci/devices/${device}/driver"
        local curr_driver="$(basename "$(realpath "${driver_path}")")"
        if [[ ! "${unbind_stack[@]}" =~ ${device} ]]; then
            if [[ ! "${curr_driver}" == "${orig_driver}" ]]; then
                detach_pci_dev "${device}"
            fi
            unbind_stack=("${device}" "${unbind_stack[@]}")
        fi
    } # End-detach

    function attach {
        local device=$(basename "$(realpath "${1}")")
        local driver="$(cat ${TMP_CONFIG_PATH}/state/pci-devs/${device}/driver.val)"
        attach_pci_dev "${device}" "${driver}"
        attach_pci_dev_post_ops "${device}"
    } # End-attach

    # Undoes any additional changes made before initially unbinding the pci
    # devices
    function attach_pci_dev_post_ops {
        local device="$(basename "$(realpath "${1}")")"

        # @TODO: Add a wait so the device can be fully activated before
        #        reattaching connected devices
        sleep 2

        # Remounts all file systems on any attached devices
        local drive_lst="${TMP_CONFIG_PATH}/state/pci-devs/${device}/sub-devs/drives.val"
        if [[ -f "${drive_lst}" && -s "${drive_lst}" && ]]; then
            remount_drives $(cat "${drive_lst}")
        fi

        # Rebind all attached USB devices
    } # End-attach_pci_dev_post_ops

    function unbind {
        traverse_pci_dev_tree "${1}" "detach" "consumer"
    } # End-unbind

    #function rebind {
    #    traverse_pci_dev_tree "${1}" "attach" "supplier"
    #} # End-rebind

    for d in ${@}; do
        if [[ -n "${d}" && (! "${unbind_stack[@]}" =~ ${d}) ]]; then
            unbind "/sys/bus/pci/devices/${d}"
        fi
    done
    for d in ${unbind_stack[@]}; do
        attach "${d}"
    done
} # End-bind_pci_devices

function bind_efi_framebuffer {
    # @TODO:  Add code to check if it is already bound before proceeding
    #echo "efi-framebuffer.0" > /sys/bus/platform/drivers/efi-framebuffer/bind
    echo "efi-framebuffer.0 > /sys/bus/platform/drivers/efi-framebuffer/bind"
} # End-bind_efi_framebuffer

function bind_vtconsoles {
    # @TODO:  Add code to check if it is already bound before proceeding
    for v in /sys/class/vtconsole/vtcon*; do
        #echo 1 > ${v}/bind
        echo "1 > ${v}/bind"
    done
} # End-bind_vtconsoles

function start_display_manager {
    # #TODO: Check the display manager's current state before trying to start it
    # systemctl start "$(cat ${TMP_CONFIG_PATH}/state/display-manager.val).service"
    echo "$(cat ${TMP_CONFIG_PATH}/state/display-manager.val).service"
} # End-start_display_manager