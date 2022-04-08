#! /bin/bash

#-----------------------------------------------------------------------------
# Libvirt: Hooks for specific system management
# https://libvirt.org/hooks.html
#     Before a QEMU guest is started, the qemu hook script is called in three
#     locations; if any location fails, the guest is not started.
#
#     ...
#
#     The second location, available Since 0.8.0 , occurs after libvirt has
#     finished labeling all resources, but has not yet started the guest,
#     called as:
#-----------------------------------------------------------------------------
function start_begin {
    load_config_data
    echo "start_begin:     Pass"
} # End-start_begin
