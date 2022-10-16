#! /bin/bash

#-----------------------------------------------------------------------------
# Libvirt: Hooks for specific system management
# https://libvirt.org/hooks.html
#     After the network is started, up & running, the script is called as:
#-----------------------------------------------------------------------------

function main {
    # set -x
    load_config_data

    if (( $DEBUG == 1 )); then
        set -x
    fi
    execute "systemd-resolve --interface \"${IF_NAME}\" --set-domain \"~${NET_DOMAIN}\" --set-dns \"${IP_ADDR}\""
    execute "firewall-cmd --change-interface=\"${IF_NAME}\" --zone=\"${ZONE}\""
} # End-main

function started_begin {
    main
} # End-started_begin
