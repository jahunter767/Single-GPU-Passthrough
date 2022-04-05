#! /bin/bash

internal_zone=("libvirt")
internal_services=("")

external_services=("")
external_zone=("")

nfs_shares=("")
nfs_user="username"
nfs_group="username"
vm_hostname="172.16.1.0/24"

# @TODO: Save the relevant values under ${TMP_CONFIG_PATH}/state/network/*.val
#        to allow for more dynamic enabling and disabling of features without
#        disrupting other VMs started before or after that require similar
#        features

# Enabling services for the specified zone
function enable_services {
    local zone=${1}
    for p in ${@:2}; do
        # firewall-cmd --add-service=${p} --zone=${zone}
        echo "--add-service=${p} --zone=${zone}"
    done
} # End-enable_services

# Export NFS shares
function export_nfs_shares {
    for ((i = 0; i < ${#nfs_shares[*]}; i++)); do
        #exportfs -o rw,sync,secure,all_squash,anonuid=$(id -u ${nfs_user}),anongid=$(id -g ${nfs_group}) ${vm_hostname}:${nfs_shares[i]}
        echo "exportfs -o rw,sync,secure,all_squash,anonuid=$(id -u ${nfs_user}),anongid=$(id -g ${nfs_group}) ${vm_hostname}:${nfs_shares[i]}"
    done
} # End-export_nfs_shares
