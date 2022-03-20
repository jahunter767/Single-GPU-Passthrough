#! /bin/bash

if_name="wanbr0"
firewall-cmd --change-interface=${if_name} --zone=libvirt
systemd-resolve --interface ${if_name} --set-domain "~wan" --set-dns "192.168.100.1"
