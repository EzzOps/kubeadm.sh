To use this script:

Save it to a file, for example, setup_k8s_cluster.sh.
Make it executable: chmod +x setup_k8s_cluster.sh.
Run it on each node, specifying the node type and the public IP address:
For the control plane node: ./setup_k8s_cluster.sh control-plane <PUBLIC_IP_ADDRESS>
For worker nodes: ./setup_k8s_cluster.sh worker <PUBLIC_IP_ADDRESS>
