#! /bin/bash

#Helpful to read output when debugging
set -x

HOOKTYPE_BASEDIR="${0%.d/**}.d"
GUEST_NAME="${1}"
HOOK_NAME="${2}"
STATE_NAME="${3}"
HOOKPATH="${HOOKTYPE_BASEDIR}/default/${HOOK_NAME}/${STATE_NAME}"

# Loads preset variables
source "${HOOKTYPE_BASEDIR}/${GUEST_NAME}/vm.conf"

# Loads default functions
if [ -f "$HOOKPATH" ] && [ -s "$HOOKPATH"] && [ -x "$HOOKPATH" ]; then
    source "$HOOKPATH"
elif [ -d "$HOOKPATH" ]; then
    while read file; do
        # check for null string
        if [ ! -z "$file" ]; then
            source "$file"
        fi
    done <<< "$(find -L "$HOOKPATH" -maxdepth 1 -type f -print;)"
fi

release_cores ${free_cores}

#unload_vfio

#reattach_usb_ctrls ${usb_ctrls[*]}
#reattach_gpu "-dev" ${gpu[*]} "-kmods" ${gpu_kmods[*]}

remount_drives

# Unexport NFS shares
for ((i = 0; i < ${#nfs_shares[*]}; i++)); do
    exportfs -u ${vm_hostname}:${nfs_shares[i]}
done

#disable_services ${external_zone} ${external_services[*]}
disable_services ${internal_zone} ${internal_services[*]}
