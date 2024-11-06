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
}


############################################################
# Variable definition                                      #
############################################################

untaint=false


############################################################
# Process the input options.                               #
############################################################

args=$(getopt -n "$(basename "$0")" -o h: --long help,untaint -- "$@") || exit 1
eval set -- "$args"

while :; do
    case $1 in
        -h|--help) Help; exit;;
        --untaint) untaint=true; shift;;
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

# Get the join command
sudo kubeadm token create --print-join-command > join_command.sh
sudo chmod +x join_command.sh

# Deploy Flannel
kubectl apply -f https://github.com/flannel-io/flannel/releases/latest/download/kube-flannel.yml