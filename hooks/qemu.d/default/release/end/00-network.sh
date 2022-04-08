#! /bin/bash

internal_zone=("libvirt")
internal_services=("")

external_services=("")
external_zone=("")

nfs_shares=("/path/to/share")
nfs_user="username"
nfs_group="username"
vm_hostname="172.16.1.0/24"

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
