#! /bin/bash

if_name="virtbr0"
firewall-cmd --change-interface=${if_name} --zone=libvirt
systemd-resolve --interface ${if_name} --set-domain "~vm" --set-dns "172.16.1.1"
systemctl start nfs-server.service

