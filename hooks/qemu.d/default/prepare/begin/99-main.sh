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
function prepare_begin {
    parse_xml
    mkdir -p ${TMP_CONFIG_PATH}/state/{drives,pci-devs}

    local desc_val="$(cat "${TMP_CONFIG_PATH}/domain/description/value")"
    readarray config_flags <<< $(parse_description_args "${desc_val}")
    echo "${config_flags[@]}" > "${TMP_CONFIG_PATH}/state/args.val"

    local renderer_count=$(renderer_check)
    if [ ${renderer_count} -eq 0 ]; then
        config_flags=("--single-gpu" "${config_flags[@]}")
    elif [ ${renderer_count} -lt 0 ]; then
        echo "ERROR: Unexpectedly low number of renders (renderer count: ${renderer_count})" 1>&2
        exit 2
    fi

    if [[ "${config_flags[@]}" =~ "--debug" ]]; then
        set -x
    fi

    for f in ${config_flags[@]}; do
        case ${f} in
            --single-gpu)
                echo "Stopping Display Manager"
                stop_display_manager
                echo "Unbinding VTconsoles"
                unbind_vtconsoles
                echo "Unbinding EFI-Framebuffer"
                unbind_efi_framebuffer
                echo "Sleep"
            ;;
            --enable-internal-services)
                echo "Adding ${internal_services[*]} services to ${internal_zone} firewall zone"
                enable_services ${internal_zone} ${internal_services[*]}
            ;;
            --enable-external-services)
                echo "Adding ${external_services[*]} services to ${external_zone} firewall zone"
                enable_services ${external_zone} ${external_services[*]}
            ;;
            --enable-nfs)
                echo "Exporting the following NFS shares to the VM"
                export_nfs_shares
            ;;
            --pin-cpu-cores)
                echo "Pinning CPU cores"
                isolate_cores
            ;;
            --debug)
                echo "Debugging was enabled"
            ;;
            *)
                echo "Warning: Undefined tag: ${f}" 1>&2
            ;;
        esac
    done

    if [[ ${#DRIVE_LIST[@]} -gt 0 && -n "${DRIVE_LIST[@]}" ]]; then
        echo "Unmounting all mounted partitions for the following drives:"
        echo "${DRIVE_LIST[@]}"
        unmount_drives "${DRIVE_LIST[@]}"
    fi

    if [[ ${#HOSTDEV_LIST[@]} -gt 0 && -n "${HOSTDEV_LIST[@]}" ]]; then
        echo "Loading VFIO modules"
        load_vfio
        echo "Unbinding the following PCI devices from their drivers:"
        echo "${HOSTDEV_LIST[@]}"
        unbind_pci_devices "${HOSTDEV_LIST[@]}"
    fi
} # End-prepare_begin
