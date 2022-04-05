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
    sleep 12
} # End-unbind_efi_framebuffer

function unbind_pci_devices {
    declare -a unbind_stack

    function detach_pci_dev {
        local d=$(basename "${1}")
        if [[ ! "${unbind_stack[@]}" =~ ${d} ]]; then
            local driver_path="/sys/bus/pci/devices/${d}/driver"
            local curr_module="$(basename "$(realpath "${driver_path}/module")")"
            if [[ ! "${curr_module}" =~ (vfio) ]]; then
                local driver="$(basename "$(realpath "${driver_path}")")"
                echo "${driver}" > "${TMP_CONFIG_PATH}/state/${d}-driver.val"
                #echo "${d}" > "/sys/bus/pci/devices/${1}/driver/unbind"
                echo "${d} > /sys/bus/pci/devices/${1}/driver/unbind"
            fi
            unbind_stack=("${d}" "${unbind_stack[@]}")
        fi
    } # End-detach_pci_dev

    function attach_pci_dev {
        local d=$(basename "${1}")
        local dev_path="/sys/bus/pci/devices/${d}"
        local vendor="$(cat ${dev_path}/vendor)"
        local device="$(cat ${dev_path}/device)"
        local dev_id="${vendor#0x}:${device#0x}"
        local driver="vfio-pci"
        #echo "${dev_id}" > "/sys/bus/pci/drivers/${driver}/new_id"
        echo "${dev_id} > /sys/bus/pci/drivers/${driver}/new_id"
    } # End-attach_pci_dev

    function traverse_pci_dev_tree {
        local curr_node="${1}"
        local action="${2}"
        local next_node="${3}"
        while read n; do
            if [[ -d "${n}" && -n "$n" ]]; then
                traverse_pci_dev_tree "$(realpath ${n})" "${action}" "${next_node}"
            fi
        done <<< $(ls -d1 ${curr_node}/${next_node}:pci:*:*:*.*/${next_node})

        if command -v "${action}"; then
            "${action}" "${curr_node}"
        else
            echo "ERROR: PCI ACTION UNDEFINED"
        fi
    } # End-traverse_pci_dev_tree

    function unbind {
        traverse_pci_dev_tree "${1}" "detach_pci_dev" "consumer"
    } # End-unbind

    #function rebind {
    #    traverse_pci_dev_tree "${1}" "attach_pci_dev" "supplier"
    #} # End-rebind

    for d in ${@}; do
        if [[ ! "${unbind_stack[@]}" =~ ${d} ]]; then
            unbind "/sys/bus/pci/devices/${d}"
        fi
    done
    for d in ${unbind_stack[@]}; do
        attach_pci_dev "${d}"
    done
} # End-unbind_pci_devices

function load_vfio {
    local vfio_kmods=("vfio" "vfio_iommu_type1" "vfio_pci")
    for v in ${vfio_kmods[*]}; do
        # modprobe ${v}
        echo ${v}
    done
} # End-load_vfio
