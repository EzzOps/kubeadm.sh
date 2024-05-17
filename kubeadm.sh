#!/bin/bash

# Function to display usage information
usage() {
  echo "Usage: $0 {control-plane|worker} <PUBLIC_IP_ADDRESS>"
  exit 1
}

# Check if the correct number of arguments is provided
if [ "$#" -ne 2 ]; then
  usage
fi

NODE_TYPE=$1
PUBLIC_IP_ADDRESS=$2

# Common steps for all nodes
setup_common() {
  sudo modprobe overlay
  sudo modprobe br_netfilter

  cat <<EOF | sudo tee /etc/sysctl.d/99-kubernetes-cri.conf
net.bridge.bridge-nf-call-iptables = 1
net.ipv4.ip_forward = 1
net.bridge.bridge-nf-call-ip6tables = 1
EOF

  sudo sysctl --system

  sudo apt-get update && sudo apt-get install -y containerd.io

  sudo mkdir -p /etc/containerd
  sudo containerd config default | sudo tee /etc/containerd/config.toml

  sudo systemctl restart containerd
  sudo systemctl status containerd

  sudo swapoff -a

  sudo apt-get update && sudo apt-get install -y apt-transport-https curl

  curl -fsSL https://pkgs.k8s.io/core:/stable:/v1.27/deb/Release.key | sudo gpg --dearmor -o /etc/apt/keyrings/kubernetes-apt-keyring.gpg

  cat <<EOF | sudo tee /etc/apt/sources.list.d/kubernetes.list
deb [signed-by=/etc/apt/keyrings/kubernetes-apt-keyring.gpg] https://pkgs.k8s.io/core:/stable:/v1.27/deb/ /
EOF

  sudo apt-get update
  sudo apt-get install -y kubelet kubeadm kubectl
  sudo apt-mark hold kubelet kubeadm kubectl
}

# Setup for the control plane node
setup_control_plane() {
  sudo kubeadm init --pod-network-cidr 192.168.0.0/16 --kubernetes-version 1.27.11

  mkdir -p $HOME/.kube
  sudo cp -i /etc/kubernetes/admin.conf $HOME/.kube/config
  sudo chown $(id -u):$(id -g) $HOME/.kube/config

  kubectl apply -f https://raw.githubusercontent.com/projectcalico/calico/v3.25.0/manifests/calico.yaml

  kubeadm token create --print-join-command
}

# Setup for the worker node
setup_worker() {
  read -p "Enter the kubeadm join command: " JOIN_COMMAND
  sudo $JOIN_COMMAND
}

# Execute the common setup for all nodes
setup_common

# Execute specific setup based on node type
case $NODE_TYPE in
  control-plane)
    setup_control_plane
    ;;
  worker)
    setup_worker
    ;;
  *)
    usage
    ;;
esac

# Display the status of the nodes
kubectl get nodes

