#!/usr/bin/env bash
set -eu

# Wait for the K3s node to become ready, then deploy the Kubernetes
# resources (Deployments, Services, and Ingress) from the confs directory.

# Tell kubectl to use this file to connect to the K3s cluster.
export KUBECONFIG=/etc/rancher/k3s/k3s.yaml

# k3s starts the API server asynchronously; wait for the node to report
# Ready before applying workloads on top of it.
until kubectl get nodes 2>/dev/null | grep -q " Ready"; do
	sleep 2
done

kubectl apply -f /home/vagrant/confs
