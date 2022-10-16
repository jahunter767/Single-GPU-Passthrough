#! /bin/bash

function unload_vfio {
    # @TODO: Check if whether the modules were loaded before starting the VM
    #        is stored and don't unload the the ones that weren't already loaded
    #        Might also need to consider checking for other running VM's that
    #        may currently be using the modules
    #        Potential file to check:
    #        ${TMP_CONFIG_PATH}/state/pci-devs/existing_modules.val
    execute "modprobe -r \"${VFIO_KMODS[@]}\""
} # End-unload_vfio

function load_drm_kmods {
    # If .val file containing drm modules exists load those modules too
    local file="${TMP_CONFIG_PATH}/state/pci-devs/drm-mods.val"
    if [[ -f "${file}" && -s "${file}" ]]; then
        local drm_mods="$(cat ${file})"
        for m in ${drm_mods}; do
            execute "modprobe \"${m}\""
        done
    fi
} # End-load_drm_kmods

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
        local dev_conf_path="${TMP_CONFIG_PATH}/state/pci-devs/${device}"
        local driver="$(cat ${dev_conf_path}/driver.val)"

        # If the driver can't be located, load the kernel module associated
        # with the driver (if the driver is associated with one)
        if [[ ! -d "/sys/bus/pci/drivers/${driver}" &&
            -f "${dev_conf_path}" && -s "${dev_conf_path}" ]]
        then
            local modules="$(cat ${dev_conf_path}/module.val)"
            for m in ${modules}; do
                execute "modprobe \"${m}\""
            done
        fi

        attach_pci_dev "${device}" "${driver}"
        attach_pci_dev_post_ops "${device}"
    } # End-attach

    # Undoes any additional changes made before initially unbinding the pci
    # devices
    function attach_pci_dev_post_ops {
        local device="$(basename $(realpath ${1}))"

        # @TODO: Add a wait so the device can be fully activated before
        #        reattaching connected devices
        sleep 2

        # Remounts all file systems on any attached devices
        local drive_lst="${TMP_CONFIG_PATH}/state/pci-devs/${device}/sub-devs/drives.val"
        if [[ -f "${drive_lst}" && -s "${drive_lst}" ]]; then
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
    if [[ ! -d "/sys/bus/platform/drivers/efi-framebuffer/efi-framebuffer.0" ]]; then
        execute "echo \"efi-framebuffer.0\" > \"/sys/bus/platform/drivers/efi-framebuffer/bind\""
    fi
} # End-bind_efi_framebuffer

function bind_vtconsoles {
    for v in /sys/class/vtconsole/vtcon*; do
        if [[ $(cat ${v}/bind) != 1 ]]; then
            execute "echo 1 > \"${v}/bind\""
        fi
    done
} # End-bind_vtconsoles

function start_display_manager {
    # #TODO: Check the display manager's current state before trying to start it
    execute "systemctl start \"$(cat ${TMP_CONFIG_PATH}/state/display-manager.val).service\""
} # End-start_display_manager
