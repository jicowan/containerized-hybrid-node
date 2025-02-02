#!/bin/bash
set -eux

CONFIG_FILE="/etc/containerd/config.toml"
BACKUP_FILE="/etc/containerd/config.toml.bak"

### Move these changes to containerd to the containerd section in the NodeConfig file
# Backup the original file
cp "$CONFIG_FILE" "$BACKUP_FILE"

# Update the configuration
sed -i 's|^root = .*|root = "/mnt/tmpfs/containerd"|' "$CONFIG_FILE"
sed -i 's|^state = .*|state = "/run/containerd"|' "$CONFIG_FILE"

# Ensure the snapshotter setting exists
if grep -q 'snapshotter =' "$CONFIG_FILE"; then
    sed -i 's|snapshotter = .*|snapshotter = "native"|' "$CONFIG_FILE"
else
    sed -i '/\[plugins\."io.containerd.grpc.v1.cri"\.containerd\]/a \ \ \ \ snapshotter = "native"' "$CONFIG_FILE"
fi

# Restart containerd to apply changes
systemctl restart containerd

echo "Containerd configuration updated and restarted successfully."
