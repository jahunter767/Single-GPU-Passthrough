#! /bin/bash

# Undoing core isolation
function release_cores {
    local allowed_user_threads="${default_user_allowedCPUs}"
    local allowed_system_threads="${default_system_allowedCPUs}"
    local allowed_init_threads="${default_init_allowedCPUs}"

    # Generated a list of threads pinned for other running VMs
    local pinned_threads=""
    for vm in $(ls -d1 ${TMP_CONFIG_PATH}/../*); do
        if [[ "$(realpath ${vm})" != "${TMP_CONFIG_PATH}" ]]; then
            local pinned_threads="${pinned_threads} \
                $(tag_list_to_array "${vm}/domain/cputune/vcpupin" \
                    "get_host_thread") "
        fi
    done

    # Removes the pinned threads from the default list of unpinned threads
    for c in ${pinned_threads}; do
        local allowed_user_threads="${allowed_user_threads/ ${c} / }"
        local allowed_system_threads="${allowed_system_threads/ ${c} / }"
        local allowed_init_threads="${allowed_init_threads/ ${c} / }"
    done

    # systemctl set-property --runtime -- user.slice AllowedCPUs="${allowed_user_threads}"
    # systemctl set-property --runtime -- system.slice AllowedCPUs="${allowed_system_threads}"
    # systemctl set-property --runtime -- init.scope AllowedCPUs="${allowed_init_threads}"
    echo "Free user.slice threads: ${allowed_user_threads}"
    echo "Free system.slice threads: ${allowed_system_threads}"
    echo "Free init.slice threads: ${allowed_init_threads}"
} # End-release_cores
