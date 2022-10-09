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
function main {
    load_config_data
    load_description_configs
    echo "started_begin:   Pass"
} # End-main

function started_begin {
    main
} # End-started_begin
