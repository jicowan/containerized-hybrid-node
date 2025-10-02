#!/bin/bash
set -e

LOG_FILE="/var/log/hybrid-node-setup.log"
mkdir -p "$(dirname $LOG_FILE)"

{
    echo "Starting hybrid node setup at $(date)"

    # Ensure swap is disabled to avoid kubelet issues
    echo "Disabling swap..."
    swapoff -a || true

    echo "Running nodeadm install..."
    # Use --containerd-source system to let nodeadm configure the existing containerd
    nodeadm install 1.31 --credential-provider ssm --containerd-source distro

    echo "Initializing node with nodeadm..."
    nodeadm init --config-source file:///usr/local/bin/nodeConfig.yaml -s cni-validation,node-ip-validation || true

    # Let nodeadm handle credential configuration

    # Extract SSM instance ID and set hostname to match
    INSTANCE_ID=$(grep "instanceID" "$LOG_FILE" | tail -1 | sed -E 's/.*"instanceID":"([^"]+)".*/\1/')
    if [ ! -z "$INSTANCE_ID" ]; then
        echo "Setting hostname to match SSM instance ID: $INSTANCE_ID"
        hostname "$INSTANCE_ID"
        echo "$INSTANCE_ID" > /etc/hostname
        echo "127.0.0.1 $INSTANCE_ID" >> /etc/hosts
        echo "Hostname set to $(hostname)"
    fi

    # Create temporary CNI config to allow the kubelet to start
    mkdir -p /etc/cni/net.d
    chmod 755 /etc/cni/net.d

    cat > /etc/cni/net.d/10-bridge.conf << EOF
{
  "cniVersion": "0.3.1",
  "name": "bridge",
  "type": "bridge",
  "bridge": "cni0",
  "isGateway": true,
  "ipMasq": true,
  "ipam": {
    "type": "host-local",
    "ranges": [
      [{"subnet": "10.244.0.0/16"}]
    ],
    "routes": [{"dst": "0.0.0.0/0"}]
  }
}
EOF
    echo "Created temporary CNI configuration for node bootstrap"

    # Enable and start kubelet service
    echo "Enabling and starting kubelet service..."

    systemctl daemon-reload || echo "Warning: Failed to reload systemd daemon, continuing anyway..."
    systemctl enable kubelet || echo "Warning: Failed to enable kubelet service, continuing anyway..."
    systemctl restart kubelet || echo "Warning: Failed to restart kubelet service, continuing anyway..."

    # Proceed with default configuration

    echo "Setup completed at $(date)"
    echo "Node is configured for EKS hybrid node with Cilium CNI"
    echo "To complete setup, install Cilium CNI using Helm from the EKS control plane"
} >> "$LOG_FILE" 2>&1