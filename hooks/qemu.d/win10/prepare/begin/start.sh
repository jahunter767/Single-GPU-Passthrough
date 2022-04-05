#! /bin/bash

internal_zone=("libvirt")
internal_services=("ssh" "nfs" "rpc-bind" "mountd")

#external_services=("ssh")
#external_zone=("home")

nfs_shares=("/path/to/share")
nfs_user="username"
nfs_group="username"
vm_hostname="172.16.1.0/24"
