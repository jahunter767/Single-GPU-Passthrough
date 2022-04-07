#!/bin/bash

NO_FORMAT="\e[0m"
GROUP_FORMAT="\e[1;34m"
RESET_FORMAT="\e[1;32m"

echo -en "${NO_FORMAT}"
echo -e "-------------------------CPU Topology-------------------------\n"

lscpu -e

echo -e "\n-------------------------IOMMU Groups-------------------------\n"

shopt -s nullglob
for g in $(ls -vd1 /sys/kernel/iommu_groups/*); do
    echo -e "${GROUP_FORMAT}IOMMU Group ${g##*/}:${NO_FORMAT}"

    for d in ${g}/devices/*; do
        PCI_FORMAT="\e[1m"
        ATTACHED_DEVICES_FORMAT="\e[0m"
        if [[ -e ${d}/reset ]]; then
            echo -en "${RESET_FORMAT}[RESET]"
            PCI_FORMAT=${RESET_FORMAT}
            ATTACHED_DEVICES_FORMAT="\e[0;32m"
        fi

        device="$(basename "${d}")"

        # Prints PCI device info
        echo -en "${PCI_FORMAT}"
        while read line; do
            echo -en "\t${line}\n"
        done <<< $(lspci -nnks "${device}")

        # Prints info of attached devices
        echo -en "${ATTACHED_DEVICES_FORMAT}"

        # Finds all the connected displays
        ports=$(ls -d1 ${d}/drm/card[0-9]/card[0-9]-*)
        if [[ ${ports} != "" && ${ports} != "." ]]; then
            echo -e "\t\tPorts:"
            for p in ${ports}; do
                echo -e "\t\t\t${p#*/card[0-9]/card[0-9]-} ($(cat "${p}/status"))"
            done
        fi

        # Finds all the connected USB devices
        usb_ctrls=$(ls -d1 ${d}/usb[0-9])
        if [[ ${usb_ctrls} != "" && ${usb_ctrls} != "." ]]; then
            echo -e "\t\tUSB Devices:"
            for uc in ${usb_ctrls}; do
                while read line; do
                    echo -en "\t\t\t${line}\n"
                done <<< $(lsusb -s ${uc#*/usb}:)
            done
        fi

        # Finds all the connected storage devices
        readarray -t block_devs <<< $(ls -d1 /dev/disk/by-path/pci-${device}*)
        if [[ "${block_devs[@]}" != "" && "${block_devs[@]}" != "." ]]; then
            storage_drives="$(realpath ${block_devs[@]%-part*} | sort -u)"
            echo -e "\t\tStorage Devices:"
            while read line; do
                echo -e "\t\t\t${line}"
            done <<< $(lsblk ${storage_drives})
            echo
        fi
        echo -en "${NO_FORMAT}"
    done;
done;
