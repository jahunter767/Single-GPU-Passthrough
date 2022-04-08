#! /bin/bash

#-----------------------------------------------------------------------------
# Libvirt: Hooks for specific system management
# https://libvirt.org/hooks.html
#     When a QEMU guest is stopped, the qemu hook script is called in two
#     locations, to match the startup.
#
#     First, since 0.8.0 , the hook is called before libvirt restores any labels:
#-----------------------------------------------------------------------------
function stopped_end {
    load_config_data
    echo "stopped_end:     Pass"
} # End-stopped_end
