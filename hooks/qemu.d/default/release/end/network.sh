#! /bin/bash

internal_zone=("libvirt")
internal_services=("")

external_zone=("")
external_services=("")

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
