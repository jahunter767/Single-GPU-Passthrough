#! /bin/bash

internal_zone=("libvirt")
internal_services=("")

external_zone=("")
external_services=("")

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
