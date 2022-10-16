#! /bin/bash

# @TODO: See todo in hooks/default/prepare/begin/network.sh

# Disabling services for the specified zone
function disable_services {
    local zone=${1}

    echo "Removing '${@:2}' from '${zone}' zone"
    for p in ${@:2}; do
        execute "firewall-cmd --remove-service=\"${p}\" --zone=\"${zone}\""
    done
} # End-disable_services

# Disabling internal services specified for each network the guest is connected
# to
function disable_internal_services {
    local network_count
    if (( ${#INTERFACE_LIST[@]} <= ${#INTERNAL_SERVICES[@]} )); then
        network_count=${#INTERFACE_LIST[@]}
    else
        network_count=${#INTERNAL_SERVICES[@]}
    fi

    for (( i = 0; i < ${network_count}; i++ )); do
        if [[ -n "${INTERNAL_SERVICES[$i]}" ]]; then
            local iface_config_path="${TMP_CONFIG_PATH}/state/interfaces/iface${i}.val"
            if [[ -s "${iface_config_path}" ]]; then
                local network="${INTERFACE_LIST[$i]##*@}"
                local zone="$(cat "${iface_config_path}")"
                disable_services "${zone}" "${INTERNAL_SERVICES[$i]}"
            fi
        fi
    done
} # End-disable_internal_services

function disable_external_services {
    for z in "${HOST_SERVICES[@]}"; do
        local zone="${z%%:*}"
        readarray -t services <<< $(
            grep -oP "([[:word:]]+(-[[:word:]]+)*)" <<< "${z##*:}")
        disable_services "${zone}" "${services[@]}"
    done
} # End-disable_external_services

# Unexport NFS shares
function unexport_nfs_shares {
    for ((i = 0; i < ${#nfs_shares[*]}; i++)); do
        execute "exportfs -u \"${vm_hostname}:${nfs_shares[i]}\""
    done
} # End-unexport_nfs_shares

# Disable SMB shares
function disable_smb_shares {
    for s in  ${smb_shares[@]}; do
        execute "restorecon -r \"${s}\""
    done
} # End-disable_smb_shares
