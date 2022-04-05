#! /bin/bash

internal_zone=("libvirt")
internal_services=("ssh" "nfs" "rpc-bind" "mountd")

external_services=("ssh")
external_zone=("home")

nfs_shares=("/path/to/share")
nfs_user="username"
nfs_group="username"
vm_hostname="172.16.1.0/24"

# Disabling services for the specified zone
function disable_services {
    zone=${1}
    for p in ${@:2}; do
        # firewall-cmd --remove-service=${p} --zone=${zone}
        echo "--remove-service=${p} --zone=${zone}"
    done
} # End-disable_services

# Unexport NFS shares
# for ((i = 0; i < ${#nfs_shares[*]}; i++)); do
#     exportfs -u ${vm_hostname}:${nfs_shares[i]}
# done
