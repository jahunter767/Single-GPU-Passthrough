#! /bin/bash

# Isolate Cores
function isolate_cores {
    # @TODO: update this function to detect existing pinned threads, determine
    #        if the threads in the list are already pinned, then pin the ones
    #        that aren't pinned and save that list of newly pinned threads.
    #        Save the details for thread pinning under the folder
    #        ${TMP_CONFIG_PATH}/state/tuning

    # @TODO: make the string comma separated
    free_cores="${CPU_THREAD_LIST[*]}"

    # systemctl set-property --runtime -- user.slice AllowedCPUs=${free_cores}
    # systemctl set-property --runtime -- system.slice AllowedCPUs=${free_cores}
    # systemctl set-property --runtime -- init.scope AllowedCPUs=${free_cores}
    echo ${free_cores}
} # End-isolate_cores
