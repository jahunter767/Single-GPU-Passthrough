#! /bin/bash

#-----------------------------------------------------------------------------
# Libvirt: Hooks for specific system management
# https://libvirt.org/hooks.html
#     The second location, available Since 0.8.0 , occurs after libvirt has
#     finished labeling all resources, but has not yet started the guest,
#     called as:
#-----------------------------------------------------------------------------
function start_begin {
    echo "start_begin:     Pass"
} # End-start_begin
