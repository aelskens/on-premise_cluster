#!/bin/bash


sudo kubeadm reset

sudo su -c "iptables -F && iptables -t nat -F && iptables -t mangle -F && iptables -X"
sudo ip link delete cni0
sudo ip link delete flannel.1