#! /bin/bash

if_name="lanbr1"
firewall-cmd --change-interface=${if_name} --zone=libvirt
ip addr add dev ${if_name} broadcast 192.168.2.255 192.168.2.254/24
