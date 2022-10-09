#! /bin/bash

# @TODO: Save the relevant values under ${TMP_CONFIG_PATH}/state/network/*.val
#        to allow for more dynamic enabling and disabling of features without
#        disrupting other VMs started before or after that require similar
#        features

# Enabling services for the specified zone
function enable_services {
    local zone=${1}

    echo "Adding '${@:2}' to '${zone}' zone"
    for p in ${@:2}; do
        # firewall-cmd --add-service=${p} --zone=${zone}
        echo "--add-service=${p} --zone=${zone}"
    done
} # End-enable_services

# Enabling internal services specified for each network the guest is connected
# to
function enable_internal_services {
    # Compare the length of INTERNAL_SERVICES and INTERFACE_LIST
    # Loop through the shorter one
    # Get the network zone from tmp/libvirt-xml/network/<network>/hookData/network/bridge/zone.val
    # Loop through the list of services in the current line of INTERNAL_SERVICES and enable them
    local network_count
    if (( ${#INTERFACE_LIST[@]} <= ${#INTERNAL_SERVICES[@]} )); then
        network_count=${#INTERFACE_LIST[@]}
    else
        network_count=${#INTERNAL_SERVICES[@]}
    fi

    for (( i = 0; i < ${network_count}; i++ )); do
        if [[ -n "${INTERNAL_SERVICES[$i]}" ]]; then
            local type="${INTERFACE_LIST[$i]%%://*}"

            local zone
            case "${type}" in
                network)
                    local network="${INTERFACE_LIST[$i]##*@}"
                    local network_config_path="${TMP_CONFIG_PATH_ROOT}/network/${network}/hookData/network"

                    local zone_path="${network_config_path}/bridge/zone.val"
                    if [[ -s "${zone_path}" ]]; then
                        zone="$(cat "${zone_path}")"
                    else
                        local bridge_path="${network_config_path}/bridge/name.val"
                        if [[ -s "${bridge_path}" ]]; then
                            local bridge="$(cat "${bridge_path}")"
                            zone="$(firewall-cmd --get-zone-of-interface "${bridge}")"
                        fi
                    fi
                    ;;
                bridge)
                    local bridge="${INTERFACE_LIST[$i]##*@}"
                    zone="$(firewall-cmd --get-zone-of-interface "${bridge}")"
                    ;;
                direct)
                    local dev="${INTERFACE_LIST[$i]##*@}"
                    zone="$(firewall-cmd --get-zone-of-interface "${dev}")"
                    ;;
                *)
                    log "WARNING: Unknown interface type: ${type}"
                    ;;
            esac

            if [[ -n "${zone}" ]]; then
                echo "${zone}" > "${TMP_CONFIG_PATH}/state/interfaces/iface${i}.val"
                enable_services "${zone}" "${INTERNAL_SERVICES[$i]}"
            else
                log "WARNING: No zone found for interface ${INTERFACE_LIST[$i]}"
            fi
        fi
    done
} # End-enable_internal_services

function enable_external_services {
    for z in "${HOST_SERVICES[@]}"; do
        local zone="${z%%:*}"
        readarray -t services <<< $(
            grep -oP "([[:word:]]+(-[[:word:]]+)*)" <<< "${z##*:}")
        enable_services "${zone}" "${services[@]}"
    done
} # End-enable_external_services

# Export NFS shares
function export_nfs_shares {
    for ((i = 0; i < ${#nfs_shares[*]}; i++)); do
        #exportfs -o rw,sync,secure,all_squash,anonuid=$(id -u ${nfs_user}),anongid=$(id -g ${nfs_group}) ${vm_hostname}:${nfs_shares[i]}
        echo "exportfs -o rw,sync,secure,all_squash,anonuid=$(id -u ${nfs_user}),anongid=$(id -g ${nfs_group}) ${vm_hostname}:${nfs_shares[i]}"
    done
} # End-export_nfs_shares

# Enable SMB shares
function enable_smb_shares {
    for s in  ${smb_shares[@]}; do
        # chcon -t samba_share_t "${s}"
        echo "chcon -t samba_share_t ${s}"
    done
} # End-enable_smb_shares
