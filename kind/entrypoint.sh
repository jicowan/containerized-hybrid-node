#!/bin/bash
set -e

echo "Starting EKS hybrid node initialization..."

# Setup basic environment and logs
LOG_FILE="/var/log/hybrid-node-setup.log"
mkdir -p "$(dirname $LOG_FILE)"

# Function to log messages to both console and log file
log() {
  local timestamp=$(date +"%Y-%m-%d %H:%M:%S")
  echo "[$timestamp] $1"
  echo "[$timestamp] $1" >> "$LOG_FILE"
}

log "Hybrid node entrypoint script starting"

# Copy and enable the hybrid-node-setup service file for systemd
mkdir -p /etc/systemd/system
cp /usr/local/bin/hybrid-node-setup.service /etc/systemd/system/
chmod 644 /etc/systemd/system/hybrid-node-setup.service

# Clean up any existing configuration that might conflict with nodeadm
rm -rf /etc/kubernetes/manifests/* 2>/dev/null || true
rm -rf /etc/kubernetes/pki/* 2>/dev/null || true
rm -rf /etc/containerd/config.toml 2>/dev/null || true
rm -f /etc/systemd/system/kubelet.service.d/* 2>/dev/null || true
rm -rf /etc/containerd/config.d/* 2>/dev/null || true

# Set up basic directories
mkdir -p /etc/eks
mkdir -p /var/lib/kubelet
mkdir -p /sys/fs/cgroup/kubepods

# Fix cgroup setup for kubelet
log "Setting up cgroup controllers for kubelet..."
mkdir -p /sys/fs/cgroup/kubepods.slice
# Try to set up cgroup controllers but don't fail if it doesn't work
echo "+cpu +cpuset +hugetlb +memory +pids" > /sys/fs/cgroup/cgroup.subtree_control 2>/dev/null || echo "Warning: Could not set cgroup controllers, continuing anyway..."

# Reload systemd to pick up any changes
systemctl daemon-reload || echo "Warning: Failed to reload systemd daemon, continuing anyway..."

# Prepare BPF filesystem for Cilium CNI
log "Setting up BPF filesystem..."
mkdir -p /sys/fs/bpf
mount -t bpf bpffs /sys/fs/bpf -o rw || log "BPF filesystem already mounted"
mount --make-shared /sys/fs/bpf
mount --bind /sys/fs/bpf /sys/fs/bpf
mount --make-rshared /sys/fs/bpf
log "BPF filesystem mounted with recursive shared propagation"

# Set up cgroup mounts for Cilium with proper sharing
log "Setting up cgroup mounts for Cilium..."
mkdir -p /run/cilium/cgroupv2

# First ensure /run is properly set up for sharing
mount --make-shared /run || log "Failed to make /run shared, continuing..."
mkdir -p /run/cilium
mount --bind /run/cilium /run/cilium || log "Failed to bind mount /run/cilium, continuing..."
mount --make-shared /run/cilium || log "Failed to make /run/cilium shared, continuing..."

# Mount the cgroup filesystem to the Cilium directory with shared propagation
if [ -d /sys/fs/cgroup/unified ]; then
    # For hybrid cgroup v1/v2 setups
    log "Using hybrid cgroup v1/v2 setup"
    mount --bind /sys/fs/cgroup/unified /run/cilium/cgroupv2 || log "Failed to bind mount unified cgroup, continuing..."
else
    # For pure cgroup v2 setups
    log "Using pure cgroup v2 setup"
    mount --bind /sys/fs/cgroup /run/cilium/cgroupv2 || log "Failed to bind mount cgroup, continuing..."
fi

# Make the mount recursively shared for proper propagation
mount --make-rshared /run/cilium/cgroupv2 || log "Failed to make cgroupv2 recursively shared, continuing..."
log "Cgroup filesystem mounted for Cilium with recursive shared propagation"

# Stop and disable any existing kubelet/containerd services to allow nodeadm to handle installation
systemctl disable --now kubelet containerd 2>/dev/null || log "Failed to disable services, continuing..."

# Enable the hybrid-node-setup service through systemd
mkdir -p /etc/systemd/system/multi-user.target.wants
ln -sf /etc/systemd/system/hybrid-node-setup.service /etc/systemd/system/multi-user.target.wants/
log "Hybrid node setup service enabled via systemd"

log "Setup completed, starting main container process"
exec "$@"
