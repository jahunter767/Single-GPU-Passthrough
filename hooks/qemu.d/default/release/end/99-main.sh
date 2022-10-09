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
function main {
    if [ -z "$(command -v "load_config_data")" ]; then
        log "ERROR: load_config_data not defined in ${HOOK_FOLDER}/default.d/${DOMAIN_NAME}"
        exit 2
    fi

    load_config_data
    load_description_configs

    local config_flags=(${CONFIG_FLAGS[@]})
    if [[ "${config_flags[@]}" =~ "--debug" ]]; then
        echo "Debugging enabled"
        set -x
    fi

    if [[ ${#HOSTDEV_LIST_PCI[@]} -gt 0 && -n "${HOSTDEV_LIST_PCI[@]}" ]]; then
        echo "Rebinding the following PCI devices to the host:"
        echo "${HOSTDEV_LIST_PCI[@]}"
        bind_pci_devices "${HOSTDEV_LIST_PCI[@]}"
        echo "Loading DRM (Direct Rendering Manager) kernel module"
        load_drm_kmods
        # echo "Unloading VFIO modules"
        # unload_vfio
    fi

    if [[ ${#DRIVE_LIST[@]} -gt 0 && -n "${DRIVE_LIST[@]}" ]]; then
        echo "Remounting all mounted partitions for the following drives:"
        echo "${DRIVE_LIST[@]}"
        remount_drives "${DRIVE_LIST[@]}"
    fi

    # Checks if all the current GPU's with graphical outputs were previously
    # bound to the VM. This check comes after rebinding all the PCI devices
    # and loading the necessary modules for the drm module as the rendering
    # devices only show up in /sys/class/drm after that
    local enable_host_graphics=1
    for r in $(get_gpu_with_output_list); do
        if [[ ! "${HOSTDEV_LIST_PCI[@]}" =~ "${r}" ]]; then
            enable_host_graphics=0
        fi
    done
    if [ ${enable_host_graphics} -eq 1 ]; then
        local config_flags=("--no-host-graphics" "${config_flags[@]}")
    fi

    declare -p config_flags
    for f in ${config_flags[@]}; do
        case ${f} in
            --no-host-graphics)
                echo "Rebinding EFI-Framebuffer"
                bind_efi_framebuffer
                echo "Rebinding VTconsoles"
                bind_vtconsoles
                echo "Starting Display Manager"
                start_display_manager
            ;;
            --enable-internal-services)
                echo "Disabling Internal Services"
                disable_internal_services
            ;;
            --enable-external-services)
                echo "Disabling External Services"
                disable_external_services
            ;;
            --enable-nfs)
                echo "Unexporting the following NFS shares from the VM:"
                echo "${nfs_shares[@]}"
                unexport_nfs_shares
            ;;
            --enable-smb)
                echo "Disabling the following SMB shares:"
                echo "${smb_shares[@]}"
                disable_smb_shares
            ;;
            --pin-cpu-cores)
                echo "Unpinning CPU cores"
                release_cores
            ;;
            --debug)
                # Pass
            ;;
            *)
                log "WARNING: Undefined tag: ${f}"
            ;;
        esac
    done

    if [ -d "${TMP_CONFIG_PATH}" ]; then
        rm -r "${TMP_CONFIG_PATH}"
    fi
} # End-main

function release_end {
    main
} # End-release_end
