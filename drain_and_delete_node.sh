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
   echo "    --control-plane           To remove the additionnal ressources deployed onto the control plane"
}


############################################################
# Variable definition                                      #
############################################################

controlplane=false


############################################################
# Process the input options.                               #
############################################################

args=$(getopt -n "$(basename "$0")" -o h: --long help,control-plane -- "$@") || exit 1
eval set -- "$args"

while :; do
    case $1 in
        -h|--help) Help; exit;;
        --control-plane) controlplane=true; shift;;
        *) shift; break;;
        \?) echo "Error: Invalid option."; exit;;
    esac
done


############################################################
# Main program.                                            #
############################################################

# Get the node to drain and delete
read -p "Node to drain and delete: " nodename

# Delete k8s-device-plugin and Flannel
if $controlplane; then
  helm delete nvdp --namespace nvidia-device-plugin
  kubectl delete -f https://github.com/flannel-io/flannel/releases/latest/download/kube-flannel.yml
fi

# Drain the node
kubectl drain $nodename --delete-emptydir-data --force --ignore-daemonsets

# Delete the node
kubectl delete node $nodename