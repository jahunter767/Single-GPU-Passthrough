#! /bin/bash

#-----------------------------------------------------------------------------
# Libvirt: Hooks for specific system management
# https://libvirt.org/hooks.html
#     Later, when network is started and there's an interface from a domain
#     to be plugged into the network, the hook script is called as:
#
#     Please note, that in this case, the script is passed both network and
#     port XMLs on its stdin.
#-----------------------------------------------------------------------------

function main {
    parse_xml

    if (( $DEBUG == 1 )); then
        set -x
    fi

    echo "port_created_begin: Pass"
} # End-main

function port_created_begin {
    main
} # End-port_created_begin
