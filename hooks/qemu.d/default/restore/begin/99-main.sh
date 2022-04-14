#! /bin/bash

#-----------------------------------------------------------------------------
# Libvirt: Hooks for specific system management
# https://libvirt.org/hooks.html
#     Since 1.2.9 , the qemu hook script is also called when restoring a saved
#     image either via the API or automatically when restoring a managed save
#     machine.
#
#     The domain XML sent to standard input of the script. In this case, the
#     script acts as a filter and is supposed to modify the domain XML and
#     print it out on its standard output. Empty output is identical to copying
#     the input XML without changing it. In case the script returns failure or
#     the output XML is not valid, restore of the image will be aborted. This
#     hook may be used, e.g., to change location of disk images for restored
#     domains.
#-----------------------------------------------------------------------------
function main {
    parse_xml
    echo "restore_begin:   Pass"
} # End-main

function restore_begin {
    main
} # End-restore_begin
