#! /bin/bash

# Isolate Cores
function isolate_cores {
    # systemctl set-property --runtime -- user.slice AllowedCPUs=${free_cores}
    # systemctl set-property --runtime -- system.slice AllowedCPUs=${free_cores}
    # systemctl set-property --runtime -- init.scope AllowedCPUs=${free_cores}
    echo ${free_cores}
} # End-isolate_cores
