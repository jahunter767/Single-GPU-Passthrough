#! /bin/bash

# Unmounts all storage drives to be passed to guest
function unmount_drives {
    function unmount_partition {
        local part="$(basename $(realpath "${1}"))"

        # @TODO: Add support for mapped block devices like LUKS2 or LVM
        # @TODO: For filesystems with multiple mount points, figure out how
        #        to detect the order to mount them in then mount them
        case "$(lsblk -dno FSTYPE /dev/${part})" in
            crypto_LUKS)
                readarray blk_dev_tree <<< $(lsblk -lnpo NAME /dev/${part})
                # Unmount all nested block devices
                for (( i = ${#blk_dev_tree[@]} - 1 ; i > 0; i-- )); do
                    unmount_partition ${blk_dev_tree[$i]}
                done

                # Unmount current device
                local mt_pt="$(findmnt -no TARGET /dev/${part})"
                if [[ -n "${mt_pt}" ]]; then
                    echo "${mt_pt}" > "${TMP_CONFIG_PATH}/state/drives/${part}.val"
                    # umount "/dev/${part}"
                    echo "umount /dev/${part}"
                fi
                # Lock encrypted partition
            ;;
            # <regex for type that represents LVM>)
            # ;;
            *)
                local mt_pt="$(findmnt -no TARGET /dev/${part})"
                if [[ -n "${mt_pt}" ]]; then
                    echo "${mt_pt}" > "${TMP_CONFIG_PATH}/state/drives/${part}.val"
                    # umount "/dev/${part}"
                    echo "umount /dev/${part}"
                fi
            ;;
        esac
    } # End-unmount_partition

    for d in ${@}; do
        local blk_dev="$(basename "$(realpath "${d}")")"

        case "$(lsblk -dno TYPE /dev/${blk_dev})" in
            part)
                unmount_partition "${blk_dev}"
            ;;
            disk)
                while read bdev; do
                    unmount_partition "${bdev}"
                done <<< $(ls -d /dev/${blk_dev}* | grep -oP "/dev/${blk_dev}+[^ ]")
            ;;
        esac
    done
} # End-unmount_drives
