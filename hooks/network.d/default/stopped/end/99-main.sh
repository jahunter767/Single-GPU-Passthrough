#! /bin/bash

#-----------------------------------------------------------------------------
# Libvirt: Hooks for specific system management
# https://libvirt.org/hooks.html
#     When a network is shut down, this script is called as:
#-----------------------------------------------------------------------------

function main {
    load_config_data

    if (( $DEBUG == 1 )); then
        set -x
    fi

    echo "stopped_end:        Pass"
} # End-main

function stopped_end {
    main
} # End-stopped_end
