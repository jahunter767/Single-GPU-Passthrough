#! /bin/bash

#-----------------------------------------------------------------------------
# Libvirt: Hooks for specific system management
# https://libvirt.org/hooks.html
#     After the network is started, up & running, the script is called as:
#-----------------------------------------------------------------------------

function main {
    set -x
    load_config_data
    systemd-resolve --interface ${IF_NAME} --set-domain "~${NET_DOMAIN}" --set-dns "${IP_ADDR}"
    firewall-cmd --change-interface=${IF_NAME} --zone=libvirt
} # End-main

function started_begin {
    main
} # End-started_begin
