#!/bin/bash

# Remove the service account
kubectl delete -f "$(dirname $0)/serviceaccount.yaml"

# Delete the deployment
helm uninstall -n kubernetes-dashboard kubernetes-dashboard