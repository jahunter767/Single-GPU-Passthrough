#! /bin/bash

# To extend the functionality of the default hooks you can either redefine
# some of the functions in the default scripts in scripts in this folder
# or uncomment the function below and add extra commands before or after the
# call of the main function (main is defined in the 99-main.sh script located
# default folder on a similar path)
#
# You can also override default variables declared in hooks/default.d/qemu
# by specifying a new assignment here (outside of the function).
# (Note: remember to maintain the same variable type). eg:
#
# internal_zone=("libvirt")
# internal_services=("ssh" "nfs" "rpc-bind" "mountd")

internal_zone=("libvirt")
internal_services=("ssh" "samba" "nfs" "rpc-bind" "mountd")

external_services=("ssh")
external_zone=("home")

nfs_shares=("/path/to/share")
nfs_user="username"
nfs_group="username"
vm_hostname="172.16.1.0/24"

smb_shares=("/path/to/share")

# function release_end {
#     # <your code here>
#     main
#     # <your code here>
# } # End-release_end
