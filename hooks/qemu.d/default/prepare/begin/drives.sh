#! /bin/bash

# Unmounts all storage drives to be passed to guest
function unmount_drives {
    for d in ${@}; do
        local blk_dev="$(basename "$(realpath "${d}")")"

        # Gets information on the partitions to be unmounted
        local fields="TYPE,MOUNTPOINTS"
        declare -A params
        while read p; do
            if [[ -n "${p}" ]]; then
                local val="${p##*=[\"\']}"
                params["${p%%=*}"]="${val%[\"\']}"
            fi
        done <<< $(lsblk -Po "${fields}" "/dev/${blk_dev}" |
            grep -oP "[^ \"\']+=[\"\'][^\"\']*[\"\']")

        # For now I'll only do auto-trmounting after stopping the VM for regular
        # partitions. For context other possible types are:
        # - crypt: encrypted file systems; I would imagine can't be
        #   remounted automatically unless there are credentials stored in
        #   the system (like in a TPM chip)
        # - disk: represents the full drive (eg. /dev/sda)
        if [[ -n "${params["MOUNTPOINTS"]}" ]]; then
            if [[ -v params["TYPE"] && "${params["TYPE"]}" == "part" ]]; then
                echo "${params["MOUNTPOINTS"]}" > "${TMP_CONFIG_PATH}/state/drives/${blk_dev}.val"
            fi
            # @TODO: Verify that this works for mapped block devices
            # umount "/dev/${blk_dev}"
            echo "umount /dev/${blk_dev}"
        fi
    done
} # End-unmount_drives
