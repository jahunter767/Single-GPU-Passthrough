#! /bin/bash

#-----------------------------------------------------------------------------
# Libvirt: Hooks for specific system management
# https://libvirt.org/hooks.html
#     Since 0.9.11 , the qemu hook script is also called at the beginning of
#     incoming migration.
#
#     The domain XML sent to standard input of the script. In this case, the
#     script acts as a filter and is supposed to modify the domain XML and
#     print it out on its standard output. Empty output is identical to copying
#     the input XML without changing it. In case the script returns failure or
#     the output XML is not valid, incoming migration will be canceled. This
#     hook may be used, e.g., to change location of disk images for incoming
#     domains.
#-----------------------------------------------------------------------------
function main {
    parse_xml
    echo "migrate_begin:   Pass"
} # End-main

function migrate_begin {
    main
} # End-migrate_begin
