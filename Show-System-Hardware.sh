#!/bin/bash

NO_FORMAT="\e[0m"
GROUP_FORMAT="\e[1;34m"
RESET_FORMAT="\e[1;32m"

echo -en "${NO_FORMAT}"
echo -e "-------------------------CPU Topology-------------------------\n"

lscpu -e

echo -e "\n-------------------------IOMMU Groups-------------------------\n"

shopt -s nullglob
for g in `find /sys/kernel/iommu_groups/* -maxdepth 0 -type d | sort -V`; do
    echo -e "${GROUP_FORMAT}IOMMU Group ${g##*/}:${NO_FORMAT}"

    for d in ${g}/devices/*; do
        PCI_FORMAT="\e[1m"
        ATTACHED_DEVICES_FORMAT="\e[0m"
        if [[ -e ${d}/reset ]]; then
            echo -en "${RESET_FORMAT}[RESET]"
            PCI_FORMAT=${RESET_FORMAT}
            ATTACHED_DEVICES_FORMAT="\e[0;32m"
        fi

        # Prints PCI device info
        echo -en "${PCI_FORMAT}"
        readarray device <<< $(lspci -nnks ${d##*/})
        #echo -e "\t$(lspci -nnks ${d##*/})"
        for (( i = 0; i < ${#device[*]}; i++ )); do
            echo -en "\t${device[i]}"
        done

        # Prints info of attached devices
        echo -en "${ATTACHED_DEVICES_FORMAT}"

        # Finds all the connected displays
        ports=$(find ${d}/drm/card[0-9+]/card[0-9+]-* -maxdepth 0 -type d)
        if [[ ${ports} != "" && ${ports} != "." ]]; then
            echo -e "\t\tPorts:"
            for p in ${ports}; do
                echo -e "\t\t\t${p#*/card[0-9+]/card[0-9+]-} ($(cat "${p}/status"))"
                #for s in `find -L $p/* -maxdepth 0 -type f`; do
                #    echo -e "\t\t\t\t${s#*/card[0-9+]-*/}: $(cat $s)";
                #done
            done
        fi

        # Finds all the connected USB devices
        usb_ctrls=$(find ${d}/usb[0-9+] -maxdepth 0 -type d)
        if [[ ${usb_ctrls} != "" && ${usb_ctrls} != "." ]]; then
            echo -e "\t\tUSB Devices:"
            for uc in ${usb_ctrls}; do
                readarray usb_devices <<< $(lsusb -s ${uc#*/usb}:)
                for (( i = 0; i < ${#usb_devices[*]}; i++ )); do
                    echo -en "\t\t\t${usb_devices[$i]}"
                done
            done
        fi

        # Finds all the connected storage devices
        storage_drives=$(find ${d}/ata*/host*/target*/[0-9]:[0-9]:[0-9]:[0-9]/block/sd* -maxdepth 0 -type d)
        if [[ ${storage_drives} != "" && ${storage_drives} != "." ]]; then
            echo -e "\t\tStorage Drives:"
            for sd in ${storage_drives}; do
                echo -e "\t\t\t$(lsblk -PS /dev/$(basename ${sd}))"
            done
            echo
        fi

        echo -en "${NO_FORMAT}"
    done;
done;
