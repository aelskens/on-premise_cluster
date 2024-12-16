#!/bin/bash


############################################################
# Help function                                            #
############################################################

Help()
{
   echo "Join node to the cluster via ssh."
   echo
   echo "Usage: start_control-plane [OPTIONS]"
   echo "Options:"
   echo "-h, --help                    Print this help message"
   echo "    --gpu                     To designate the control plane as a GPU node"
}


############################################################
# Variable definition                                      #
############################################################

gpu=false


############################################################
# Process the input options.                               #
############################################################

args=$(getopt -n "$(basename "$0")" -o h: --long help,gpu -- "$@") || exit 1
eval set -- "$args"

while :; do
    case $1 in
        -h|--help) Help; exit;;
        --gpu) gpu=true; shift;;
        *) shift; break;;
        \?) echo "Error: Invalid option."; exit;;
    esac
done


############################################################
# Main program.                                            #
############################################################

read -p "User: " username
read -p "Hostname: " hostname

# Get the join command
OUTPUT="$(sudo kubeadm token create --print-join-command)"

# Execute the join command on the remote node through ssh
ssh -tt $username@$hostname "eval $OUTPUT"

# Add labels to node for GPU support
# cf. https://github.com/NVIDIA/k8s-device-plugin/blob/main/deployments/helm/nvidia-device-plugin/values.yaml#L68
if $gpu; then
  # On discrete-GPU based systems NFD adds the following label where 10de is the NVIDIA PCI vendor ID
  kubectl label nodes $hostname feature.node.kubernetes.io/pci-10de.present=true
  # On some Tegra-based systems NFD detects the CPU vendor ID as NVIDIA
  kubectl label nodes $hostname feature.node.kubernetes.io/cpu-model.vendor_id="NVIDIA"
  # We allow a GPU deployment to be forced by setting the following label to "true"
  kubectl label nodes $hostname nvidia.com/gpu.present=true
fi