# On-Premise Kubernetes Cluster Setup Guide

This repository provides scripts and instructions for setting up an on-premise Kubernetes (K8s) cluster with multiple nodes.

<!-- TO CONTINUE: state my sources -->

## Prerequisites

Each node in the cluster requires a Linux-based operating system. Ensure this requirement is met on each node before proceeding with the setup.

<details open>
<summary><b><font size="+2">Setup</font></b></summary>

## Node Setup

To install the necessary tools on each node, use the `setup_node.sh` script included in this repository. This script configures all required dependencies for each node to join the K8s cluster.

> **Note**  
> This script is intended for Linux distributions, specifically Ubuntu. If you are using another Linux distribution, update the `DISTRO` variable within the script to match your operating system.

## Control Plane Setup

Choose one node to serve as the control plane and run the `setup_control-plane.sh` script on it to install additional dependencies specific to the control plane.

</details>

<details open>
<summary><b><font size="+2">Starting the K8s cluster</font></b></summary>

## Starting the Control Plane

After setting up the control plane, use the `start_control-plane.sh` script to initialize and start the cluster.

> **Note**  
> This script allows you to specify whether the control plane should be "tainted" (i.e., restricted) to prevent scheduling workloads on the control plane node itself. See the [Kubernetes documentation on control plane node isolation](https://kubernetes.io/docs/setup/production-environment/tools/kubeadm/create-cluster-kubeadm/#control-plane-node-isolation) for more details.

## Adding Nodes to the Cluster

To add additional nodes to the cluster, use the `join_command.sh` script generated by `kubeadm`. Run the command provided in `join_command.sh` on each node you wish to add to the cluster.

</details>

<details>
<summary><b><font size="+2">Deploy K8s dashboard</font></b></summary>
</br>

This section refers to the subfolder name `dashboard`. With it you will be able to deploy the [K8s dashboard](https://github.com/kubernetes/dashboard/tree/master) useful for monitoring the cluster in terms of memory consumption, deployments, ... .

Use the `dashboard_deployment.sh` script to deploy the dashboard onto your cluster. This should generate a bearer token (cf. [K8s documentation](https://kubernetes.io/docs/reference/access-authn-authz/authentication/)) for an admin account as `./bearer-token.tk`.

<!-- TO CONTINUE: with port forwarding and delete deployement -->

</details>

<details>
<summary><b><font size="+2">Cluster Teardown</font></b></summary>

To remove nodes and tear down the on-premise K8s cluster, follow these steps for each node, starting with the worker nodes and ending with the control plane node.

### Step 1: Drain and Delete a Node \[CONTROL PLANE\]

On the control plane node, use the `drain_and_delete_node.sh` script to safely drain and remove a specific node from the cluster. The script will prompt you to input the name of the node to remove.

### Step 2: Cleanup \[REMOVED NODE\]

On each node removed from the cluster, run the `cleanup.sh` script to clean up any residual configuration and prepare the node for future use or re-joining.

</details>