#! /bin/bash

function unload_vfio {
    vfio_kmods=("vfio" "vfio_iommu_type1" "vfio_pci")
    for v in ${vfio_kmods[*]}; do
        # modprobe -r ${v}
        echo ${v}
    done
} # End-unload_vfio

function bind_pci_devices {
    # # Rebind the GPU to the host
    # for g in ${gpu[*]}; do
    #     virsh nodedev-reattach ${g}
    # done

    # # Reload all GPU drivers
    # for k in ${kmods[*]}; do
    #     modprobe ${k}
    # done

    function unbind {
        c=$(basename "${1}")
        echo $(basename $(realpath "${1}/driver")) > "${TMP_CONFIG_PATH}/state/${c}-driver.val"
        #echo $(basename "${1}") > "${1}/driver/unbind"
        echo "${c}"
    } # End-unbind

    function unbind_helper {
        readarray consumer_lst <<< $(find ${1}/consumer:pci:*:*:*.*/consumer -maxdepth 0)
        if [[ ${#consumer_lst[@]} -eq 0 && $(basename "${1}/driver/module") =~ (vfio) ]] ; then
            unbind "${1}"
        else
            for consumer in ${1}/consumer:pci:*:*:*.*/consumer; do
                unbind_helper "$(realpath ${consumer})"
            done
            unbind "${1}"
        fi
    } # End-unbind_helper

    function rebind {
        c=$(basename "${1}")
        vendor="$(cat ${1}/vendor)"
        device="$(cat ${1}/device)"
        dev_id="${vendor#0x}:${device#0x}"
        driver="$(cat ${TMP_CONFIG_PATH}/state/${c}-driver.val)"
        #echo "${dev_id}" > "/sys/bus/pci/drivers/${driver}/new_id"
        echo "${dev_id}"
    } # End-rebind

    function rebind_helper {
        readarray producer_lst <<< $(find ${1}/producer:pci:*:*:*.*/producer -maxdepth 0)
        if [ ${#producer_lst[@]} -eq 0 ] ; then
            rebind "${1}"
        else
            for producer in ${1}/producer:pci:*:*:*.*/producer; do
                rebind_helper "$(realpath ${producer})"
            done
            rebind "${1}"
        fi
    } # End-rebind_helper

    for d in ${@}; do
        unbind_helper "/sys/bus/pci/devices/${d}"
        rebind_helper "/sys/bus/pci/devices/${d}"
    done
} # End-bind_pci_devices

function bind_efi_framebuffer {
    # echo "efi-framebuffer.0" > /sys/bus/platform/drivers/efi-framebuffer/bind
    echo "efi-framebuffer.0"
} # End-bind_efi_framebuffer

function bind_vtconsoles {
    for v in /sys/class/vtconsole/vtcon*; do
        # echo 1 > ${v}/bind
        echo ${v}/bind
    done
} # End-bind_vtconsoles

# By: Mateus Souza
function start_display_manager {
    # systemctl start "$(cat ${TMP_CONFIG_PATH}/state/display-manager.val).service"
    cat "${TMP_CONFIG_PATH}/state/display-manager.val.service"
} # End-start_display_manager
