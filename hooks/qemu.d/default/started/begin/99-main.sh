#! /bin/bash

#-----------------------------------------------------------------------------
# Libvirt: Hooks for specific system management
# https://libvirt.org/hooks.html
#     Before a QEMU guest is started, the qemu hook script is called in three
#     locations; if any location fails, the guest is not started.
#
#     ...
#
#     The third location, 0.9.13 , occurs after the QEMU process has
#     successfully started up:
#-----------------------------------------------------------------------------
function started_begin {
    load_config_data
    echo "started_begin:   Pass"
} # End-started_begin
