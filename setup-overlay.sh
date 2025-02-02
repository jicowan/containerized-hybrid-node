# Create the overlay mount structure
mkdir -p /mnt/tmpfs
mount -t tmpfs tmpfs /mnt/tmpfs

# Create necessary directories for containerd
mkdir -p /mnt/tmpfs/containerd /mnt/tmpfs/upper /mnt/tmpfs/work

# Ensure permissions are correct
chown -R root:root /mnt/tmpfs

# Restart containerd to apply changes
systemctl restart containerd