#! /bin/bash

# Enabling services for the specified zone
function enable_services {
    zone=${1}
    for p in ${@:2}; do
        firewall-cmd --add-service=${p} --zone=${zone}
    done
} # End-enable_services

