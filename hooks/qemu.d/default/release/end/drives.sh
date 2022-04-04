#! /bin/bash

# Remount all storage drives
function remount_drives {
    for d in ${@}; do
        # mount -a "${d}-part"*
        echo "-a ${d}-part"*
    done
} # End-remount_drives
