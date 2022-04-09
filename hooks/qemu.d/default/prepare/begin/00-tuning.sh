#! /bin/bash

# Isolate Cores
function isolate_cores {
    readarray -t all_threads <<< $(ls -dv /dev/cpu/*)

    # Generates a string listing all the currently unpinned threads
    function parse_free_threads {
        local allowed_threads="${@}"
        if [[ -n "${allowed_threads}" ]]; then
            for c in ${allowed_threads}; do
                if [[ "${c}" =~ ([0-9]+)-([0-9]+) ]]; then
                    local start="${c%-*}"
                    local end="${c#*-}"
                    for (( i = ${start}; i <= ${end}; i++ )); do
                        local free_threads="${free_threads} ${i} "
                    done
                elif [[ "${c}" =~ ([0-9]+) ]]; then
                    local free_threads="${free_threads} ${c} "
                fi
            done
        else
            local free_threads=" ${all_threads[@]#/dev/cpu/} "
        fi

        echo "${free_threads}"
    } # End-parse_free_threads

    local allowed_user_threads="$(parse_free_threads \
        "$(systemctl show -P AllowedCPUs user.slice)")"
    local allowed_system_threads="$(parse_free_threads \
        "$(systemctl show -P AllowedCPUs system.slice)")"
    local allowed_init_threads="$(parse_free_threads \
        "$(systemctl show -P AllowedCPUs init.slice)")"

    # Removes the threads to be pinned from the list
    for c in ${CPU_THREAD_LIST[@]}; do
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
} # End-isolate_cores
