#! /bin/bash

# Remount all storage drives
function remount_drives {
    for d in ${@}; do
        # mount ${d}-part*
        echo "${d}-part*"
    done
} # End-remount_drives
