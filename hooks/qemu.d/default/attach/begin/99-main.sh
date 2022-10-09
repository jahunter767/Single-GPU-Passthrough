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
    if [[ -d "${TMP_CONFIG_PATH}/state" ]]; then
        rm -r "${TMP_CONFIG_PATH}/state"
    fi
    mkdir -p ${TMP_CONFIG_PATH}/state/{drives,pci-devs,interfaces}

    parse_description_configs
    echo "attach_begin:    Pass"
} # End-main

function attach_begin {
    main
} # End-attach_begin
