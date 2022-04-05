#! /bin/bash

internal_zone=("libvirt")
internal_services=("ssh" "nfs" "rpc-bind" "mountd")

external_services=("ssh")
external_zone=("home")

nfs_shares=("/path/to/share")
nfs_user="username"
nfs_group="username"
vm_hostname="172.16.1.0/24"

# Enabling services for the specified zone
function enable_services {
    zone=${1}
    for p in ${@:2}; do
        # firewall-cmd --add-service=${p} --zone=${zone}
        echo "--add-service=${p} --zone=${zone}"
    done
} # End-enable_services

# Export NFS shares
# for ((i = 0; i < ${#nfs_shares[*]}; i++)); do
#     exportfs -o rw,sync,secure,all_squash,anonuid=$(id -u ${nfs_user}),anongid=$(id -g ${nfs_group}) ${vm_hostname}:${nfs_shares[i]}
# done
