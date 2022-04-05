#! /bin/bash

# Undoing core isolation
function release_cores {
    # @TODO: update this function to read system state before starting the VM
    #        from ${TMP_CONFIG_PATH}/state/tuning/*.val then revert the
    #        properties to what they were before.
    #        It might be worth considering detecting the properties of other
    #        VMs to determine if any currently running VMs that might have
    #        been started after the current one required similar settings

    # @TODO: make the string comma separated
    free_cores="${CPU_THREAD_LIST[*]}"

    # systemctl set-property --runtime -- user.slice AllowedCPUs=""
    # systemctl set-property --runtime -- system.slice AllowedCPUs=""
    # systemctl set-property --runtime -- init.scope AllowedCPUs=""
    echo "release cores ${free_cores}"
} # End-release_cores
