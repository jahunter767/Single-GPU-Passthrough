#! /bin/bash

#-----------------------------------------------------------------------------
# Libvirt: Hooks for specific system management
# https://libvirt.org/hooks.html
#     When the domain from previous case is shutting down, the interface is
#     unplugged. This leads to another script invocation:
#
#     And again, as in previous case, both network and port XMLs are passed
#     onto script's stdin.
#-----------------------------------------------------------------------------

function main {
    parse_xml
    echo "port_deleted_begin: Pass"
} # End-main

function port_deleted_begin {
    main
} # End-port_deleted_begin
