#! /bin/bash

#-----------------------------------------------------------------------------
# Libvirt: Hooks for specific system management
# https://libvirt.org/hooks.html
#     Since 0.9.13 , the qemu hook script is also called when the QEMU driver
#     is told to attach to an externally launched QEMU process.
#     It is called as:
#-----------------------------------------------------------------------------
function main {
    parse_xml
    echo "attach_begin:    Pass"
} # End-main

function attach_begin {
    main
} # End-attach_begin
