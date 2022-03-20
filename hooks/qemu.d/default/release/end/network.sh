#! /bin/bash

# Disabling services for the specified zone
function disable_services {
    zone=${1}
    for p in ${@:2}; do
        firewall-cmd --remove-service=${p} --zone=${zone}
    done
} # End-disable_services

