#! /bin/bash

#-----------------------------------------------------------------------------
# Libvirt: Hooks for specific system management
# https://libvirt.org/hooks.html
#     When a QEMU guest is stopped, the qemu hook script is called in two
#     locations, to match the startup.
#
#     ...
#
#     Then, after libvirt has released all resources, the hook is called again,
#     since 0.9.0 , to allow any additional resource cleanup:
#-----------------------------------------------------------------------------
function release_end {
    if [ -z "$(command -v "load_config_data")" ]; then
        echo "ERROR: load_config_data not defined in ${HOOK_FOLDER}/default.d/${DOMAIN_NAME}" 1>&2
        exit 2
    fi

    load_config_data
    readarray -t config_flags <<< $(cat "${TMP_CONFIG_PATH}/state/args.val")
    config_flags=("${config_flags[@]## }")

    if [[ "${config_flags[@]}" =~ "--debug" ]]; then
        set -x
    fi

    if [[ ${#HOSTDEV_LIST[@]} -gt 0 && -n "${HOSTDEV_LIST[@]}" ]]; then
        echo "Rebinding the following PCI devices to the host:"
        echo "${HOSTDEV_LIST[@]}"
        bind_pci_devices "${HOSTDEV_LIST[@]}"
        echo "Unloading VFIO modules"
        unload_vfio
    fi

    if [[ ${#DRIVE_LIST[@]} -gt 0 && -n "${DRIVE_LIST[@]}" ]]; then
        echo "Remounting all mounted partitions for the following drives:"
        echo "${DRIVE_LIST[@]}"
        remount_drives "${DRIVE_LIST[@]}"
    fi

    # @TODO: Verify this
    # This check comes after rebinding all the PCI devices as the rendering
    # devices only show up when a GPU is bound to it's original driver
    local renderer_count=$(renderer_check)
    if [ ${renderer_count} -eq 0 ]; then
        config_flags=("--single-gpu" "${config_flags[@]}")
    elif [ ${renderer_count} -lt 0 ]; then
        echo "ERROR: Unexpectedly low number of renders (renderer count: ${renderer_count})" 1>&2
        exit 2
    fi

    declare -a flags
    flags=${@}
    for f in ${config_flags[@]}; do
        case ${f} in
            --single-gpu)
                echo "Rebinding EFI-Framebuffer"
                echo "Rebinding VTconsoles"
                echo "Starting Display Manager"
            ;;
            --enable-internal-services)
                echo "Removing ${internal_services[*]} services from ${internal_zone} firewall zone"
                disable_services ${internal_zone} ${internal_services[*]}
            ;;
            --enable-external-services)
                echo "Removing ${external_services[*]} services from ${external_zone} firewall zone"
                disable_services ${external_zone} ${external_services[*]}
            ;;
            --enable-nfs)
                echo "Unexporting the following NFS shares from the VM:"
                echo "${nfs_shares[@]}"
                unexport_nfs_shares
            ;;
            --pin-cpu-cores)
                echo "Unpinning CPU cores"
                release_cores
            ;;
            --debug)
                echo "Debugging was enabled"
            ;;
            *)
                echo "Warning: Undefined tag: ${f}" 1>&2
            ;;
        esac
    done

    if [ -d "${TMP_CONFIG_PATH}" ]; then
        rm -r "${TMP_CONFIG_PATH}"
    fi
} # End-release_end
