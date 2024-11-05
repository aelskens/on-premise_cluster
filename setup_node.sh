#!/bin/bash


############################################################
# Help function                                            #
############################################################

Help()
{
   echo "Setup the node to install all the dependencies."
   echo
   echo "Usage: setup_node [OPTIONS]"
   echo "Options:"
   echo "-h, --help                    Print this help message"
   echo "-d, --distro                  The Linux distribution that match the node's operating system, defaults to ubuntu"
   echo "    --kubernetes-version      The version of Kubernetes to install, defaults to 1.31"
   echo "    --control-plane           To install additional dependencies specific to the control plane, along with the standard setup"
}


############################################################
# Variable definition                                      #
############################################################

distro=ubuntu
k8sversion=1.31
controlplane=false


############################################################
# Process the input options.                               #
############################################################

args=$(getopt -n "$(basename "$0")" -o hd: --long help,distro:,kubernetes-version:,control-plane -- "$@") || exit 1
eval set -- "$args"

while :; do
    case $1 in
        -h|--help) Help; exit;;
        -d|--distro) distro=$2; shift 2;;
        --kubernetes-version) k8sversion=$2; shift 2;;
        --control-plane) controlplane=true; shift;;
        *) shift; break;;
        \?) echo "Error: Invalid option."; exit;;
    esac
done


############################################################
# Main program.                                            #
############################################################

sudo apt-get update
sudo apt install apt-transport-https curl -y

# Install Docker along with containerd (see https://docs.docker.com/engine/install/ubuntu/)
sudo apt-get update
sudo apt-get install ca-certificates curl
sudo install -m 0755 -d /etc/apt/keyrings
sudo curl -fsSL https://download.docker.com/linux/$distro/gpg -o /etc/apt/keyrings/docker.asc
sudo chmod a+r /etc/apt/keyrings/docker.asc
echo \
  "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.asc] https://download.docker.com/linux/ubuntu \
  $(. /etc/os-release && echo "$VERSION_CODENAME") stable" | \
  sudo tee /etc/apt/sources.list.d/docker.list > /dev/null
sudo apt-get update
sudo apt-get install docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin

# Configure containerd
sudo mkdir -p /etc/containerd
sudo containerd config default | sudo tee /etc/containerd/config.toml
sudo sed -i 's/SystemdCgroup = false/SystemdCgroup = true/1' /etc/containerd/config.toml
sudo systemctl restart containerd

# Install Kubernetes with kubeadm (see https://kubernetes.io/docs/setup/production-environment/tools/kubeadm/install-kubeadm/)
sudo apt-get update
sudo apt-get install -y apt-transport-https ca-certificates curl gpg
curl -fsSL https://pkgs.k8s.io/core:/stable:/v$k8sversion/deb/Release.key | sudo gpg --dearmor -o /etc/apt/keyrings/kubernetes-apt-keyring.gpg
echo \
  "deb [signed-by=/etc/apt/keyrings/kubernetes-apt-keyring.gpg] https://pkgs.k8s.io/core:/stable:/v$k8sversion/deb/ /" | \
  sudo tee /etc/apt/sources.list.d/kubernetes.list
sudo apt-get update
sudo apt-get install -y kubelet kubeadm kubectl
sudo apt-mark hold kubelet kubeadm kubectl
sudo systemctl enable --now kubelet

# Disable swap
sudo swapoff -a
sudo modprobe br_netfilter
sudo sysctl -w net.ipv4.ip_forward=1

if $control_plane; then
  # Install Helm
  curl -fsSL -o get_helm.sh https://raw.githubusercontent.com/helm/helm/main/scripts/get-helm-3
  chmod 700 get_helm.sh
  ./get_helm.sh
fi