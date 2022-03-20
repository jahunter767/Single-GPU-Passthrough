#! /bin/bash

if_name="lanbr0"
firewall-cmd --change-interface=${if_name} --zone=libvirt
ip link set enp31s0 master ${if_name}
ip addr add dev ${if_name} broadcast 192.168.1.255 192.168.1.254/24

