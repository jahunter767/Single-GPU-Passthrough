#! /bin/bash

#-----------------------------------------------------------------------------
# Libvirt: Hooks for specific system management
# https://libvirt.org/hooks.html
#     The third location, 0.9.13 , occurs after the QEMU process has
#     successfully started up:
#-----------------------------------------------------------------------------
function started_begin {
    echo "started_begin:   Pass"
} # End-started_begin
