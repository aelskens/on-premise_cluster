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
   echo "    --no-install              Skip the installation part, defaults to false"
   echo "    --force-install-docker    Reinstall Docker, defaults to false. Uneventful when --no-install is provided"
   echo "    --no-gpu-support          Skip the installation of nvidia-container-toolkit, defaults to false. Uneventful when --no-install is provided"
   echo "    --force-install-k8s       Reinstall Kubernetes, defaults to false. Uneventful when --no-install is provided"
   echo "    --kubernetes-version      The version of Kubernetes to install, defaults to 1.31"
   echo "    --control-plane           To install additional dependencies specific to the control plane, along with the standard setup. Uneventful when --no-install is provided"
}


############################################################
# Variable definition                                      #
############################################################

distro=ubuntu
noinstall=false
forceinstalldocker=false
nogpusupport=false
forceinstallk8s=false
k8sversion=1.31
controlplane=false


############################################################
# Process the input options.                               #
############################################################

args=$(getopt -n "$(basename "$0")" -o hd: --long help,distro:,no-install,force-install-docker,no-gpu-support,force-install-k8s,kubernetes-version:,control-plane -- "$@") || exit 1
eval set -- "$args"

while :; do
    case $1 in
        -h|--help) Help; exit;;
        -d|--distro) distro=$2; shift 2;;
        --no-install) noinstall=true; shift;;
        --force-install-docker) forceinstalldocker=true; shift;;
        --no-gpu-support) nogpusupport=true; shift;;
        --force-install-k8s) forceinstallk8s=true; shift;;
        --kubernetes-version) k8sversion=$2; shift 2;;
        --control-plane) controlplane=true; shift;;
        *) shift; break;;
        \?) echo "Error: Invalid option."; exit;;
    esac
done


############################################################
# Main program.                                            #
############################################################

if ! $noinstall; then
  sudo apt-get update
  sudo apt install apt-transport-https curl -y

  # Install Docker along with containerd (see https://docs.docker.com/engine/install/ubuntu/)
  if $forceinstalldocker || ! [ $(which docker) ] || ! [ $(which containerd) ]; then
    # Remove existing installation (not complete)
    for pkg in docker.io docker-doc docker-compose docker-compose-v2 podman-docker containerd runc; do sudo apt-get remove $pkg; done
    # Install Docker
    sudo apt-get update
    sudo apt install ca-certificates -y
    sudo install -m 0755 -d /etc/apt/keyrings
    sudo curl -fsSL https://download.docker.com/linux/$distro/gpg -o /etc/apt/keyrings/docker.asc
    sudo chmod a+r /etc/apt/keyrings/docker.asc
    echo \
      "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.asc] https://download.docker.com/linux/ubuntu \
      $(. /etc/os-release && echo "$VERSION_CODENAME") stable" | \
      sudo tee /etc/apt/sources.list.d/docker.list > /dev/null
    sudo apt-get update
    sudo apt install docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin -y
  fi

  # Configure containerd
  sudo mkdir -p /etc/containerd
  sudo containerd config default | sudo tee /etc/containerd/config.toml > /dev/null
  sudo sed -i 's/SystemdCgroup = false/SystemdCgroup = true/1' /etc/containerd/config.toml
  sudo systemctl restart containerd

  # Set up GPU support
  if ! $nogpusupport; then
    # Install nvidia-container-toolkit for GPU support
    if ! [ $(which nvidia-ctk) ]; then
      # Pop-OS has its own way to prioritize the package repo to install from, this allows to install the latest nvidia version
      # cf. https://github.com/NVIDIA/nvidia-container-toolkit/issues/23#issuecomment-1149806160
      sudo cp "$(dirname $0)/pop-os_nvidia-repo_fix"  /etc/apt/preferences.d/nvidia-docker-pin-1002
      curl -fsSL https://nvidia.github.io/libnvidia-container/gpgkey | sudo gpg --dearmor -o /usr/share/keyrings/nvidia-container-toolkit-keyring.gpg \
      && curl -s -L https://nvidia.github.io/libnvidia-container/stable/deb/nvidia-container-toolkit.list | \
        sed 's#deb https://#deb [signed-by=/usr/share/keyrings/nvidia-container-toolkit-keyring.gpg] https://#g' | \
        sudo tee /etc/apt/sources.list.d/nvidia-container-toolkit.list
      sudo sed -i -e '/experimental/ s/^#//g' /etc/apt/sources.list.d/nvidia-container-toolkit.list
      sudo apt-get update
      sudo apt-get install -y nvidia-container-toolkit
    fi
    
    sudo nvidia-ctk runtime configure --runtime=docker --set-as-default
    sudo systemctl restart docker
    # Requires nivida-container-toolkit>=1.14.0-rc2 for containerd support
    # cf. https://github.com/NVIDIA/nvidia-docker/issues/1781#issuecomment-1690729112
    sudo nvidia-ctk runtime configure --runtime=containerd --set-as-default --config=/etc/containerd/config.toml
    sudo systemctl restart containerd
  fi

  # Install Kubernetes with kubeadm (see https://kubernetes.io/docs/setup/production-environment/tools/kubeadm/install-kubeadm/)
  if $forceinstallk8s || ! [ $(which kubectl) ] || ! [ $(which kubeadm) ]; then
    sudo apt-get update
    sudo apt install -y apt-transport-https ca-certificates curl gpg
    curl -fsSL https://pkgs.k8s.io/core:/stable:/v$k8sversion/deb/Release.key | sudo gpg --dearmor -o /etc/apt/keyrings/kubernetes-apt-keyring.gpg
    echo \
      "deb [signed-by=/etc/apt/keyrings/kubernetes-apt-keyring.gpg] https://pkgs.k8s.io/core:/stable:/v$k8sversion/deb/ /" | \
      sudo tee /etc/apt/sources.list.d/kubernetes.list
    sudo apt-get update
    sudo apt install -y kubelet kubeadm kubectl
    sudo apt-mark hold kubelet kubeadm kubectl
    sudo systemctl enable --now kubelet
  fi

  if $controlplane && ! [ $(which helm) ]; then
    # Install Helm
    curl -fsSL -o get_helm.sh https://raw.githubusercontent.com/helm/helm/main/scripts/get-helm-3
    chmod 700 get_helm.sh
    ./get_helm.sh
  fi
fi

# Disable swap
sudo swapoff -a
sudo modprobe br_netfilter
sudo sysctl -w net.ipv4.ip_forward=1