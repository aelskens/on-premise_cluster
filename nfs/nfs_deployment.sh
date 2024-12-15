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
   echo "    --no-pv                   Skip the deployment of the persistent volume resource, defaults to false"
   echo "    --no-pvc                  Skip the deployment of the persistent volume claim resource, defaults to false"
}


############################################################
# Variable definition                                      #
############################################################

pv=true
pvc=true


############################################################
# Process the input options.                               #
############################################################

args=$(getopt -n "$(basename "$0")" -o h: --long help,no-pv,no-pvc -- "$@") || exit 1
eval set -- "$args"

while :; do
    case $1 in
        -h|--help) Help; exit;;
        --no-pv) pv=false; shift;;
        --no-pvc) pvc=false; shift;;
        *) shift; break;;
        \?) echo "Error: Invalid option."; exit;;
    esac
done


############################################################
# Main program.                                            #
############################################################

# Deploy the persistent volume linked to the NFS server
if $pv; then
  kubectl apply -f "$(dirname $0)/nfspersistentvolume.yaml"
fi

# Deploy the persistent volume claim bound to the NFS PV
if $pvc; then
  kubectl create namespace distributed-ray
  kubectl apply -f "$(dirname $0)/nfspersistentvolumeclaim.yaml"
fi