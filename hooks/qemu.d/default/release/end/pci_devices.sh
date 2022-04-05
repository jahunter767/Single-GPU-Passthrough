#! /bin/bash

function unload_vfio {
    # @TODO: Check if whether the modules were loaded before starting the VM
    #        is stored and don't unload the the ones that weren't already loaded
    #        Might also need to consider checking for other running VM's that
    #        may currently be using the modules
    #        Potential file to check:
    #        ${TMP_CONFIG_PATH}/state/pci_devices/existing_modules.val
    for v in ${VFIO_KMODS[@]}; do
        # modprobe -r ${v}
        echo ${v}
    done
} # End-unload_vfio

function bind_pci_devices {
    declare -a unbind_stack

    function detach {
        local device=$(basename "$(realpath "${1}")")
        local orig_driver="$(cat ${TMP_CONFIG_PATH}/state/${device}-driver.val)"
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
        local driver="$(cat ${TMP_CONFIG_PATH}/state/${device}-driver.val)"
        attach_pci_dev "${device}" "${driver}"
    } # End-attach

    function unbind {
        traverse_pci_dev_tree "${1}" "detach" "consumer"
    } # End-unbind

    #function rebind {
    #    traverse_pci_dev_tree "${1}" "attach" "supplier"
    #} # End-rebind

    for d in ${@}; do
        if [[ ! "${unbind_stack[@]}" =~ ${d} ]]; then
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
    cat "${TMP_CONFIG_PATH}/state/display-manager.val.service"
} # End-start_display_manager
