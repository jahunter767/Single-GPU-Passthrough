#! /bin/bash

#-----------------------------------------------------------------------------
# Libvirt: Hooks for specific system management
# https://libvirt.org/hooks.html
#     Before a QEMU guest is started, the qemu hook script is called in three
#     locations; if any location fails, the guest is not started.
#
#     The first location, since 0.9.0 , is before libvirt performs any resource
#     labeling, and the hook can allocate resources not managed by libvirt such
#     as DRBD or missing bridges. This is called as:
#-----------------------------------------------------------------------------
function main {
    parse_xml
    if [[ -d "${TMP_CONFIG_PATH}/state" ]]; then
        rm -r "${TMP_CONFIG_PATH}/state"
    fi
    mkdir -p ${TMP_CONFIG_PATH}/state/{drives,pci-devs,interfaces}

    parse_description_configs
    local config_flags=(${CONFIG_FLAGS[@]})

    # Checks if all the current GPU's with graphical outputs are to be passed
    # to the VM
    local disable_host_graphics=1
    readarray -t gpu_with_output_list <<< "$(get_gpu_with_output_list)"
    for r in ${gpu_with_output_list[@]}; do
        # If one gpu with outputs is not included in the lust of devices to be
        # passed to the guest then don't disable host graphics
        if [[ ! "${HOSTDEV_LIST_PCI[@]}" =~ "${r}" ]]; then
            local disable_host_graphics=0
        fi
    done
    if [[ (( ${disable_host_graphics} == 1 )) &&
          -n "${gpu_with_output_list[@]}" ]];
    then
        local config_flags=(${config_flags[@]} "--no-host-graphics")
    fi

    # @TODO: Check that all devices in the iommu groups of the devices to be
    #        passed through are bound to vfio
    # @TODO: Add check for virtualized graphics in XML if the only remaining
    #        GPU is to be passed to the VM
    # @TODO: Check that all drives to be passed through are not also connected
    #        to any PCI device that will be passed through
    # @TODO: Check that any files used by the hypervisor aren't located on a
    #        drive that will be passed through
    # @TODO: Explore adding support for GPU passthrough on laptops with Optimius
    #        or Prime

    if [[ "${config_flags[@]}" =~ "--dry-run" ]]; then
        echo "Dry-run enabled"
        DRY_RUN=1
    fi
    if [[ "${config_flags[@]}" =~ "--debug" ]]; then
        echo "Debugging enabled"
        DEBUG=1
        set -x
    fi

    declare -p config_flags
    for f in ${config_flags[@]}; do
        case ${f} in
            --no-host-graphics)
                # @TODO: Save the drm modules before stopping the display
                # manager because killing kwin_wayland seems to unload the
                # driver breaking unload_drm_kmods in the process
                echo "Stopping Display Manager"
                stop_display_manager
                echo "Unbinding VTconsoles"
                unbind_vtconsoles
                echo "Unbinding EFI-Framebuffer"
                unbind_efi_framebuffer
                echo "Unloading DRM (Direct Rendering Manager) kernel modules"
                unload_drm_kmods "${gpu_with_output_list[@]}"
            ;;
            --enable-internal-services)
                echo "Enabling Internal Services"
                enable_internal_services
            ;;
            --enable-external-services)
                echo "Enabling External Services"
                enable_external_services
            ;;
            --enable-nfs)
                echo "Exporting the following NFS shares to the VM:"
                echo "${nfs_shares[@]}"
                export_nfs_shares
            ;;
            --enable-smb)
                echo "Enabling the following SMB shares:"
                echo "${smb_shares[@]}"
                enable_smb_shares
            ;;
            --pin-cpu-cores)
                echo "Pinning CPU cores"
                isolate_cores
            ;;
            --debug)
                # Pass
            ;;
            --dry-run)
                # Pass
            ;;
            *)
                log "WARNING: Undefined tag: ${f}"
            ;;
        esac
    done

    if [[ ${#DRIVE_LIST[@]} -gt 0 && -n "${DRIVE_LIST[@]}" ]]; then
        echo "Unmounting all mounted partitions for the following drives:"
        echo "${DRIVE_LIST[@]}"
        unmount_drives "${DRIVE_LIST[@]}"
    fi

    if [[ ${#HOSTDEV_LIST_PCI[@]} -gt 0 && -n "${HOSTDEV_LIST_PCI[@]}" ]]; then
        # echo "Loading VFIO modules"
        # load_vfio
        echo "Unbinding the following PCI devices from their drivers:"
        echo "${HOSTDEV_LIST_PCI[@]}"
        unbind_pci_devices "${HOSTDEV_LIST_PCI[@]}"
    fi
} # End-main

function prepare_begin {
    main
} # End-prepare_begin
