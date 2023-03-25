#! /bin/bash

# Author: Mateus Souza
function stop_display_manager {
    local managers=("sddm" "gdm" "lightdm" "lxdm" "xdm" "mdm")
    for m in ${managers}; do
        if $(systemctl is-active --quiet "$m.service"); then
            echo "${m}" > "${TMP_CONFIG_PATH}/state/display-manager.val"
            execute "systemctl stop \"${m}.service\""

            # Stopping any additional processes/services related to the desktop
            # environment that may prevent the GPU specific DRM module from
            # being unloaded or the GPU from being unbound from the module due
            # to them still using the GPU
            case "${m}" in
                gdm)
                    execute "killall \"gdm-x-session\""
                    ;;
                sddm)
                    #execute "killall \"plasmashell\""
                    execute "killall \"kwin_wayland\""
                    #execute "killall \"kwin_x11\""
                    ;;
                *)
                    log "WARNING: Unrecognized display manager"
                    ;;
            esac
        fi
    done
} # End-stop_display_manager

function unbind_vtconsoles {
    for v in /sys/class/vtconsole/vtcon*; do
        if [[ $(cat ${v}/bind) != 0 ]]; then
            execute "echo 0 > \"${v}/bind\""
        fi
    done
} # End-unbind_vtconsoles

function unbind_efi_framebuffer {
    if [[ -d "/sys/bus/platform/drivers/efi-framebuffer/efi-framebuffer.0" ]]; then
        execute "echo \"efi-framebuffer.0\" > \"/sys/bus/platform/drivers/efi-framebuffer/unbind\""

        # Avoid a Race condition by waiting 2 seconds. This can be calibrated
        # to be shorter or longer if required for your system
        sleep 2
    fi
} # End-unbind_efi_framebuffer

function unbind_pci_devices {
    declare -a unbind_stack

    # Prepares the pci device to be unbound. This includes tasks like detecting
    # and unmounting filesystems or detaching downstream devices attached to it
    function detach_pci_dev_prep {
        local device="$(basename "$(realpath "${1}")")"
        local driver_path="/sys/bus/pci/devices/${device}/driver"
        local driver="$(basename "$(realpath "${driver_path}")")"

        local dev_conf_path="${TMP_CONFIG_PATH}/state/pci-devs/${device}"
        mkdir -p "${dev_conf_path}/sub-devs"
        echo "${driver}" > "${dev_conf_path}/driver.val"
        if [[ -d "${driver_path}/module" ]]; then
            local module="$(basename "$(realpath "${driver_path}/module")")"
            echo "$(get_module_list ${module})" > "${dev_conf_path}/module.val"
        fi

        # Unmounts all file systems on any attached devices
        readarray -t blk_devs <<< $(ls -d /dev/disk/by-path/pci-${device}-*-part*)
        if [[ -n "${blk_devs[@]}" ]]; then
            local drives="$(realpath ${blk_devs[@]} | sort -u)"
            echo "${drives}" > "${dev_conf_path}/sub-devs/drives.val"
            unmount_drives "${drives}"
        fi

        # Unbinds all attached USB devices
        # while read usb_dev; do
        #     local vend="$(cat "${usb_dev}/idVendor")"
        #     local prod="$(cat "${usb_dev}/idProduct")"
        #     local usb_dev_id="${vend} ${prod}"
        #     # Store the driver name in ${TMP_CONFIG_PATH}/state/drivers/usb/${usb_dev_id}.val
        #     echo "${usb_dev_id} > ${usb_dev}/driver/unbind"
        # done <<< $(ls -d1 /sys/bus/pci/devices/${device}/usb+([0-9])/+([0-9])-+([0-9]))
    } # End-detach_pci_dev_prep

    function detach {
        local device=$(basename "$(realpath "${1}")")
        local driver_path="/sys/bus/pci/devices/${device}/driver"
        local curr_module="$(basename "$(realpath "${driver_path}/module")")"
        if [[ ! "${unbind_stack[@]}" =~ ${device} ]]; then
            if [[ ! "${curr_module}" =~ (vfio) ]]; then
                detach_pci_dev_prep "${device}"
                detach_pci_dev "${device}"
            fi
            unbind_stack=("${device}" "${unbind_stack[@]}")
        fi
    } # End-detach

    function attach {
        local device=$(basename "$(realpath "${1}")")
        local driver="vfio-pci"
        if [[ ! -d "/sys/bus/pci/drivers/${driver}" ]]; then
            load_vfio
        fi
        attach_pci_dev "${device}" "${driver}"
    } # End-attach

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
} # End-unbind_pci_devices

function unload_drm_kmods {
    local gpus=(${@})
    local pci_dev_state_path="${TMP_CONFIG_PATH}/state/pci-devs"
    declare -a root_mod_list
    declare -a mod_list
    for g in ${gpus}; do
        local dev_path="/sys/bus/pci/devices/${g}"
        local driver="$(basename "$(realpath "${dev_path}/driver")")"
        local mod="$(basename "$(realpath "${dev_path}/driver/module")")"
        local temp=($(get_module_list "${mod}"))

        mkdir -p "${pci_dev_state_path}/${g}"
        echo "${driver}}" > "${pci_dev_state_path}/${g}/driver.val"
        echo "${temp[@]}" > "${pci_dev_state_path}/${g}/module.val"

        if [[ ! "${root_mod_list[@]} ${mod_list[@]}" =~ "${mod}" ]]; then
            root_mod_list=(${root_mod_list[@]} "${mod}")
            mod_list=(${mod_list[@]} ${temp[@]:1})
        fi
    done

    echo "${mod_list[@]}" > "${TMP_CONFIG_PATH}/state/pci-devs/drm-mods.val"
    for (( i = ${#mod_list[@]} - 1; i >= 0 ; i-- )); do
        execute "modprobe -r \"${mod_list[$[i]]}\""
    done
} # End-unload_drm_kmods

function load_vfio {
    # @TODO: It might be worth it to store if they were already loaded so we
    #        don't unload them if they were already loaded
    #        If they are to be stored, the best place might be
    #        ${TMP_CONFIG_PATH}/state/pci-devs/existing_modules.val
    for v in ${VFIO_KMODS[@]}; do
        execute "modprobe \"${v}\""
    done
} # End-load_vfio
