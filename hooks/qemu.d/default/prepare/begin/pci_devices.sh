#! /bin/bash

# Author: Mateus Souza
function stop_display_manager {
    local managers=("sddm" "gdm" "lightdm" "lxdm" "xdm" "mdm" "display-manager")
    for m in $managers; do
        if systemctl is-active --quiet "$m.service"; then
            echo "${m}" > "${TMP_CONFIG_PATH}/state/display-manager.val"
            # systemctl stop "${m}.service"
            echo "${m}.service"
        fi
    done
} # End-stop_display_manager

function unbind_vtconsoles {
    # @TODO:  Add code to check if it is already unbound before proceeding
    for v in /sys/class/vtconsole/vtcon*; do
        #echo 0 > ${v}/bind
        echo "0 > ${v}/bind"
    done
} # End-unbind_vtconsoles

function unbind_efi_framebuffer {
    # @TODO:  Add code to check if it is already unbound before proceeding
    #echo "efi-framebuffer.0" > /sys/bus/platform/drivers/efi-framebuffer/unbind
    echo "efi-framebuffer.0 > /sys/bus/platform/drivers/efi-framebuffer/unbind"

    # Avoid a Race condition by waiting 2 seconds. This can be calibrated
    # to be shorter or longer if required for your system
    sleep 5
} # End-unbind_efi_framebuffer

function unbind_pci_devices {
    declare -a unbind_stack

    function detach {
        local device=$(basename "$(realpath "${1}")")
        local driver_path="/sys/bus/pci/devices/${device}/driver"
        local curr_module="$(basename "$(realpath "${driver_path}/module")")"
        if [[ ! "${unbind_stack[@]}" =~ ${device} ]]; then
            if [[ ! "${curr_module}" =~ (vfio) ]]; then
                detach_pci_dev "${device}"
            fi
            unbind_stack=("${device}" "${unbind_stack[@]}")
        fi
    } # End-detach

    function attach {
        local device=$(basename "$(realpath "${1}")")
        local driver="vfio-pci"
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
} # End-unbind_pci_devices

function load_vfio {
    # @TODO: It might be worth it to store if they were already loaded so we
    #        don't unload them if they were already loaded
    #        If they are to be stored, the best place might be
    #        ${TMP_CONFIG_PATH}/state/pci_devices/existing_modules.val
    for v in ${VFIO_KMODS[@]}; do
        # modprobe ${v}
        echo ${v}
    done
} # End-load_vfio
