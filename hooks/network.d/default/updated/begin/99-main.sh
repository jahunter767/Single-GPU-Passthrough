#! /bin/bash

#-----------------------------------------------------------------------------
# Libvirt: Hooks for specific system management
# https://libvirt.org/hooks.html
#     When network is updated, the hook script is called as:
#-----------------------------------------------------------------------------

function main {
    parse_xml

    if (( $DEBUG == 1 )); then
        set -x
    fi

    echo "updated_begin:      Pass"
} # End-main

function updated_begin {
    main
} # End-updated_begin
