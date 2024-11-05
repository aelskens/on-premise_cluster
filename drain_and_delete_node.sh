#!/bin/bash


# Get the node to drain and delete
read -p "Node to drain and delete: " nodename

# Drain the node
kubectl drain $nodename --delete-emptydir-data --force --ignore-daemonsets

# Delete the node
kubectl delete node $nodename