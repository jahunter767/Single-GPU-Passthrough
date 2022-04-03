#! /bin/bash

# Undoing core isolation
function release_cores {
    systemctl set-property --runtime -- user.slice AllowedCPUs=""
    systemctl set-property --runtime -- system.slice AllowedCPUs=""
    systemctl set-property --runtime -- init.scope AllowedCPUs=""
} # End-release_cores
