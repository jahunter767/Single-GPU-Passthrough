#! /bin/bash

if_name="lxcbr1"
firewall-cmd --change-interface=${if_name} --zone=libvirt
systemd-resolve --interface ${if_name} --set-domain "~lxc" --set-dns "172.16.2.1"
