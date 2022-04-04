#! /bin/bash

# By: Mateus Souza
function stop_display_manager {
    managers=("sddm" "gdm" "lightdm" "lxdm" "xdm" "mdm" "display-manager")
    for m in $managers; do
        if systemctl is-active --quiet "$m.service"; then
            echo "${m}" > "${TMP_CONFIG_PATH}/state/display-manager.val"
            # systemctl stop "${m}.service"
            echo "${m}.service"
        fi
    done
} # End-stop_display_manager

function unbind_vtconsoles {
    for v in /sys/class/vtconsole/vtcon*; do
        # echo 0 > ${v}/bind
        echo ${v}/bind
    done
} # End-unbind_vtconsoles

function unbind_efi_framebuffer {
    # echo "efi-framebuffer.0" > /sys/bus/platform/drivers/efi-framebuffer/unbind
    echo "efi-framebuffer.0"

    # Avoid a Race condition by waiting 2 seconds. This can be calibrated
    # to be shorter or longer if required for your system
    # sleep 12
} # End-unbind_efi_framebuffer

function unbind_pci_devices {
    # # Unload all GPU drivers
    # for k in ${kmods[*]}; do
    #     modprobe -r ${k}
    # done

    # # Unbind the GPU to be used in the vm
    # for g in ${gpu[*]}; do
    #     virsh nodedev-detach ${g}
    # done

    function unbind {
        c=$(basename "${1}")
        echo $(basename $(realpath "${1}/driver")) > "${TMP_CONFIG_PATH}/state/${c}-driver.val"
        #echo $(basename "${1}") > "${1}/driver/unbind"
        echo "${c}"
    } # End-unbind

    function unbind_helper {
        readarray consumer_lst <<< "$(find ${1}/consumer:pci:*:*:*.*/consumer -maxdepth 0)"
        if [[ ${#consumer_lst[@]} == 0 && !($(basename "${1}/driver/module") =~ (vfio)) ]] ; then
            unbind "${1}"
        else
            for consumer in ${consumer_lst[@]}; do
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
        driver="vfio-pci"
        #echo "${dev_id}" > "/sys/bus/pci/drivers/${driver}/new_id"
        echo "${dev_id}"
    } # End-rebind

    function rebind_helper {
        readarray producer_lst <<< $(find ${1}/producer:pci:*:*:*.*/producer -maxdepth 0)
        if [ ${#producer_lst[@]} -eq 0 ] ; then
            rebind "${1}"
        else
            for producer in ${producer_lst}; do
                rebind_helper "$(realpath ${producer})"
            done
            rebind "${1}"
        fi
    } # End-rebind_helper

    for d in ${@}; do
        unbind_helper "/sys/bus/pci/devices/${d}"
        rebind_helper "/sys/bus/pci/devices/${d}"
    done
} # End-unbind_pci_devices

function load_vfio {
    vfio_kmods=("vfio" "vfio_iommu_type1" "vfio_pci")
    for v in ${vfio_kmods[*]}; do
        # modprobe ${v}
        echo ${v}
    done
} # End-load_vfio
