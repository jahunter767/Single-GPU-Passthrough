#! /bin/bash

# @TODO: See todo in hooks/default/prepare/begin/network.sh

# Disabling services for the specified zone
function disable_services {
    local zone=${1}
    for p in ${@:2}; do
        # firewall-cmd --remove-service=${p} --zone=${zone}
        echo "--remove-service=${p} --zone=${zone}"
    done
} # End-disable_services

# Unexport NFS shares
function unexport_nfs_shares {
    for ((i = 0; i < ${#nfs_shares[*]}; i++)); do
        #exportfs -u ${vm_hostname}:${nfs_shares[i]}
        echo "exportfs -u ${vm_hostname}:${nfs_shares[i]}"
    done
} # End-unexport_nfs_shares

# Disable SMB shares
function disable_smb_shares {
    for s in  ${smb_shares[@]}; do
        # restorecon -r "${s}"
        echo "restorecon -r ${s}"
    done
} # End-disable_smb_shares
