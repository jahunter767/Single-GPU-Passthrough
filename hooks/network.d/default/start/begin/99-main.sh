#! /bin/bash

#-----------------------------------------------------------------------------
# Libvirt: Hooks for specific system management
# https://libvirt.org/hooks.html
#     Since 1.2.2 , before a network is started, this script is called as:
#-----------------------------------------------------------------------------

function main {
    parse_xml
    if [[ -d "${TMP_CONFIG_PATH}/state" ]]; then
        rm -r "${TMP_CONFIG_PATH}/state"
    fi

    if (( $DEBUG == 1 )); then
        set -x
    fi

    echo "start_begin:        Pass"
} # End-main

function start_begin {
    main
} # End-start_begin
