#!/bin/bash

# Deploy the dashboard
helm repo add kubernetes-dashboard https://kubernetes.github.io/dashboard/
helm upgrade --install kubernetes-dashboard kubernetes-dashboard/kubernetes-dashboard --create-namespace --namespace kubernetes-dashboard

# Deploy a service account for an admin user
kubectl apply -f "$(dirname $0)/serviceaccount.yaml"

# Create a bearer token
kubectl -n kubernetes-dashboard create token admin-user > "$(dirname $0)/bearer-token.tk"