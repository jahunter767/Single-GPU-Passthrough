#! /bin/bash

#-----------------------------------------------------------------------------
# Libvirt: Hooks for specific system management
# https://libvirt.org/hooks.html
#     Since 0.9.13 , the qemu hook script is also called when the libvirtd
#     daemon restarts and reconnects to previously running QEMU processes.
#     If the script fails, the existing QEMU process will be killed off.
#     It is called as:
#-----------------------------------------------------------------------------
function main {
    parse_xml
    if [[ -d "${TMP_CONFIG_PATH}/state" ]]; then
        rm -r "${TMP_CONFIG_PATH}/state"
    fi
    mkdir -p ${TMP_CONFIG_PATH}/state/{drives,pci-devs,interfaces}

    parse_description_configs
    echo "reconnect_begin: Pass"
} # End-main

function reconnect_begin {
    main
} # End-reconnect_begin
