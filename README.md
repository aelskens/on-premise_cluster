# On-Premise Kubernetes Cluster Setup Guide

This repository provides scripts and instructions for setting up an on-premise Kubernetes (K8s) cluster with multiple nodes. This was inspired by [Ian Belcher's blog](https://ianbelcher.me/tech-blog/creating-a-bare-bones-on-premises-k8s-cluster-from-old-hardware) and [DevOps Pro K8s tutorial](https://github.com/devopsproin/certified-kubernetes-administrator/tree/main/Cluster%20Setup#multi-node-kubernetes-cluster-setup-using-kubeadm).

## Prerequisites

Each node in the cluster requires a Linux-based operating system. Ensure this requirement is met on each node before proceeding with the setup.

<details open>
<summary><b><font size="+2">Node Setup</font></b></summary>
<br>

To install the necessary tools on each node, use the `setup_node.sh` script included in this repository. This script configures all required dependencies for each node to join the K8s cluster.

On the node you choose to serve as the **control plane**, run `setup_node.sh` with the `--control-plane` flag. This installs additional dependencies specific to the control plane, along with the standard setup required for all nodes.

> **NOTE**  
> This script is intended for Linux distributions, specifically Ubuntu. If you are using another Linux distribution, use the flag `-d` followed by the name of the distribution that match your operating system.
>
> Additionally, the `setup_node.sh` script can be use by providing `--no-install` to skip all installation and still setting up the node for cluster use.

</details>

<details open>
<summary><b><font size="+2">Starting the K8s cluster</font></b></summary>

## Starting the Control Plane

After setting up the control plane, use the `start_control-plane.sh` script to initialize and start the cluster.

For a GPU-enabled control plane, ensure you include the `--gpu` option during the execution of the script to activate GPU support.

> **NOTE**  
> This script allows you, with the `--untaint` flag, to specify whether the control plane should be "tainted" (i.e., restricted) to prevent scheduling workloads on the control plane node itself. See the [Kubernetes documentation on control plane node isolation](https://kubernetes.io/docs/setup/production-environment/tools/kubeadm/create-cluster-kubeadm/#control-plane-node-isolation) for more details.

## Adding Nodes to the Cluster

To expand your cluster with additional nodes, use the `join_node.sh` script. This script will guide you through the process by prompting for the `username` and `hostname` of the machine you wish to add. It then securely executes the join command over an SSH connection.

For GPU-enabled nodes, ensure you include the `--gpu` option during the execution of the script to activate GPU support.

> **IMPORTANT**  
> Since the join command requires elevated privileges, the script may prompt you to enter the sudo password for the specified user to complete the process.

</details>

<details open>
<summary><b><font size="+2">Add persistence to cluster</font></b></summary>
</br>

The `nfs` subfolder provides resources designed to enable persistent storage within the cluster by deploying a Persistent Volume (PV) and Persistent Volume Claim (PVC) pair. These resources facilitate mounting a Network File System (NFS) directly onto the cluster's pods. The implementation of these resources draws inspiration from the detailed guidelines outlined in the [use-nfs-storage](https://docs.mirantis.com/mke/3.6/ops/deploy-apps-k8s/persistent-storage/use-nfs-storage.html) documentation.

## Deploying the PV and PVC

Run the `nfs_deployment.sh` script from the control plane to deploy the PV and PVC on your cluster.

## Tearing down the PV and PVC

Run the `nfs_delete.sh` script to release the PV and PVC resources.

> **NOTE**  
> For both `nfs_deployment.sh` and `nfs_delete.sh`, you can specify whether the deployment/removal should skip one of the resource or not with either providing `--no-pv` or `--no-pvc`.

</details>

<details>
<summary><b><font size="+2">Manage K8s dashboard</font></b></summary>
</br>

The `dashboard` subfolder contains resources for deploying the [K8s dashboard](https://github.com/kubernetes/dashboard), a web-based interface useful for monitoring cluster metrics such as memory consumption, deployments, and more.

### Deploying the dashboard

1. Run the `dashboard_deployment.sh` script from the control plane to deploy the dashboard on your cluster. This will create an admin account and generate a bearer token (see [K8s authentication documentation](https://kubernetes.io/docs/reference/access-authn-authz/authentication/)), which will be saved as `./bearer-token.tk`.

2. **Accessing the dashboard \[CLIENT MACHINE\]**
   - **Copy the kubeconfig file**: On the machine where you want to access the dashboard (client machine), copy the kubeconfig file from the control plane node (`$HOME/.kube/config`) to your local machine.
   - **Start port forwarding**: Run the `dashboard_port_forward.sh` script to forward the dashboard service to your local machine. You will be prompted to provide the path to the kubeconfig file to ensure it connects to the correct cluster.

3. **Access the dashboard \[CLIENT MACHINE\]**
   - Open your browser and go to `https://localhost:8443/#/login`.
   - When prompted for authentication, enter the bearer token generated during deployment (`./bearer-token.tk`), which provides access to the dashboard.

### Tearing down the dashboard

To remove the dashboard deployment, run the `dashboard_delete.sh` script. This will delete all resources associated with the K8s dashboard.

</details>

<details>
<summary><b><font size="+2">Cluster Teardown</font></b></summary>
</br>

To remove nodes and tear down the on-premise K8s cluster, follow these steps for each node, starting with the worker nodes and ending with the control plane node.

### Step 0: Delete All Deployments \[CONTROL PLANE\]

Before removing nodes, ensure that all resources deployed with `kubectl apply -f ...`, `helm install ...`, or any other tool are stopped or deleted. This will prevent any lingering workloads or services from interfering with the teardown.

### Step 1: Drain and Delete a Node \[CONTROL PLANE\]

On the control plane node, use the `drain_and_delete_node.sh` script to safely drain and remove a specific node from the cluster. The script will prompt you to input the name of the node to remove.

### Step 2: Cleanup \[REMOVED NODE\]

On each node removed from the cluster, run the `cleanup.sh` script to clean up any residual configuration and prepare the node for future use or re-joining.

</details>