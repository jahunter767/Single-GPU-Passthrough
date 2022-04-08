#! /bin/bash

# @TODO: may need to check that a mount point is available before mounting

# Remounts all storage drives
function remount_drives {
    for d in ${@}; do
        local blk_dev="$(basename "$(realpath "${d}")")"

        # For now I'll only do auto-remounting after stopping the VM for regular
        # partitions. For context other possible types are:
        # - crypt: encrypted file systems; I would imagine can't be
        #   remounted automatically unless there are credentials stored in
        #   the system (like in a TPM chip)
        # - disk: represents the full drive (eg. /dev/sda)
        if [[ -e "${TMP_CONFIG_PATH}/state/drives/${blk_dev}.val" ]]; then
            #mount "/dev/${blk_dev}" "$(cat "${TMP_CONFIG_PATH}/state/drives/${blk_dev}.val")"
            echo "mount /dev/${blk_dev} $(cat "${TMP_CONFIG_PATH}/state/drives/${blk_dev}.val")"
        fi
    done
} # End-remount_drives
