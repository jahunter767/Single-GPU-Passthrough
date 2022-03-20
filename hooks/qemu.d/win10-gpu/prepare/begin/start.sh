#! /bin/bash

# Helpful to read output when debugging
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

enable_services ${external_zone} ${external_services[*]}
enable_services ${internal_zone} ${internal_services[*]}

# Export NFS shares
for ((i = 0; i < ${#nfs_shares[*]}; i++)); do
    exportfs -o rw,sync,secure,all_squash,anonuid=$(id -u ${nfs_user}),anongid=$(id -g ${nfs_group}) ${vm_hostname}:${nfs_shares[i]}
done

unmount_drives ${drives[*]}

detach_gpu "-dev" ${gpu[*]} "-kmods" ${gpu_kmods[*]}
detach_usb_ctrls ${usc_ctrls[*]}
load_vfio

isolate_cores ${free_cores}

