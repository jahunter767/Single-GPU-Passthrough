#! /bin/bash

# Unmounts all storage drives to be passed to guest
function unmount_drives {
    # Unmounts all mounted partitions of the drives
    for d in ${@}; do
        umount "/dev/disk/by-id/${d}-part"*
    done
} # End-unmount_drives

