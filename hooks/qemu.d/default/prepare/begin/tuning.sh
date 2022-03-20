#! /bin/bash

# Isolate Cores
function isolate_cores {
    free_cores=${1}
    systemctl set-property --runtime -- user.slice AllowedCPUs=${free_cores}
    systemctl set-property --runtime -- system.slice AllowedCPUs=${free_cores}
    systemctl set-property --runtime -- init.scope AllowedCPUs=${free_cores}
} # End-isolate_cores

