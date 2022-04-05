#! /bin/bash

function unload_vfio {
    vfio_kmods=("vfio" "vfio_iommu_type1" "vfio_pci")
    for v in ${vfio_kmods[*]}; do
        # modprobe -r ${v}
        echo ${v}
    done
} # End-unload_vfio

function bind_pci_devices {
    declare -a unbind_stack

    function detach_pci_dev {
        local d=$(basename "${1}")
        if [[ ! "${unbind_stack[@]}" =~ ${d} ]]; then
            local driver_path="/sys/bus/pci/devices/${d}/driver"
            local curr_module="$(basename "$(realpath "${driver_path}/module")")"
            if [[ "${curr_module}" =~ (vfio) ]]; then
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
        local driver="$(cat ${TMP_CONFIG_PATH}/state/${d}-driver.val)"
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
    # systemctl start "$(cat ${TMP_CONFIG_PATH}/state/display-manager.val).service"
    cat "${TMP_CONFIG_PATH}/state/display-manager.val.service"
} # End-start_display_manager
