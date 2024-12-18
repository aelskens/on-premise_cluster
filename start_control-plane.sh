#!/bin/bash


############################################################
# Help function                                            #
############################################################

Help()
{
   echo "Initialize and start the cluster."
   echo
   echo "Usage: start_control-plane [OPTIONS]"
   echo "Options:"
   echo "-h, --help                    Print this help message"
   echo "    --untaint                 To untaint the control plane, allowing to schedule workloads on it"
   echo "    --gpu                     To designate the control plane as a GPU node"
}


############################################################
# Variable definition                                      #
############################################################

untaint=false
gpu=false
HOSTNAME="$(hostname)"

############################################################
# Process the input options.                               #
############################################################

args=$(getopt -n "$(basename "$0")" -o h: --long help,untaint,gpu -- "$@") || exit 1
eval set -- "$args"

while :; do
    case $1 in
        -h|--help) Help; exit;;
        --untaint) untaint=true; shift;;
        --gpu) gpu=true; shift;;
        *) shift; break;;
        \?) echo "Error: Invalid option."; exit;;
    esac
done


############################################################
# Main program.                                            #
############################################################

# Launch the cluster
sudo kubeadm init --pod-network-cidr=10.244.0.0/16
mkdir -p $HOME/.kube
sudo cp /etc/kubernetes/admin.conf $HOME/.kube/config
sudo chown $(id -u):$(id -g) $HOME/.kube/config

# Untaint the control plane
if $untaint; then
  kubectl taint nodes $HOSTNAME node-role.kubernetes.io/control-plane-
fi

# # Get the join command
# sudo kubeadm token create --print-join-command > join_command.sh
# sudo sed -i '1s/^/sudo /' join_command.sh
# sudo chmod +x join_command.sh

# Deploy Flannel
kubectl apply -f https://github.com/flannel-io/flannel/releases/latest/download/kube-flannel.yml

# Add labels to control-plane for GPU support
# cf. https://github.com/NVIDIA/k8s-device-plugin/blob/main/deployments/helm/nvidia-device-plugin/values.yaml#L68
if $gpu; then
  # On discrete-GPU based systems NFD adds the following label where 10de is the NVIDIA PCI vendor ID
  kubectl label nodes $HOSTNAME feature.node.kubernetes.io/pci-10de.present=true
  # On some Tegra-based systems NFD detects the CPU vendor ID as NVIDIA
  kubectl label nodes $HOSTNAME feature.node.kubernetes.io/cpu-model.vendor_id="NVIDIA"
  # We allow a GPU deployment to be forced by setting the following label to "true"
  kubectl label nodes $HOSTNAME nvidia.com/gpu.present=true
fi

# Deploy k8s-device-plugin
helm repo add nvdp https://nvidia.github.io/k8s-device-plugin
helm repo update
helm upgrade -i nvdp nvdp/nvidia-device-plugin --namespace nvidia-device-plugin --create-namespace