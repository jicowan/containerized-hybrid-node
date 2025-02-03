#!/bin/bash
set -e

LOG_FILE="/var/log/nodeadm_poststart_commands.log"

# Function to run commands after the main process starts
run_post_start_commands() {
    mount -t tmpfs tmpfs /mnt/tmpfs
    # Create necessary directories for containerd
    mkdir -p /mnt/tmpfs/containerd /mnt/tmpfs/upper /mnt/tmpfs/work
    # Ensure permissions are correct
    chown -R root:root /mnt/tmpfs
    echo "Waiting for the main process to initialize..."
    sleep 5  # Adjust the sleep time or use polling for readiness checks
    echo "Executing post-start tasks..."
    systemctl enable containerd
    systemctl start containerd
    echo "Checking containerd readiness..."
    retries=5
    while ! systemctl is-active --quiet containerd; do
        if [ $retries -eq 0 ]; then
            echo "Error: containerd service failed to start."
            exit 1
        fi
        echo "Waiting for containerd to become active... ($retries retries left)"
        retries=$((retries - 1))
        sleep 2
    done
    echo "containerd is active."
    
    if ! pgrep -x "dockerd" > /dev/null; then
        echo "Starting Docker daemon..."
        dockerd &
        sleep 5  # Wait for Docker daemon to start
    fi
    
    {
        nodeadm install 1.31 --credential-provider ssm --containerd-source none
        nodeadm init -c file:///usr/local/bin/nodeConfig.yaml
        
    } >>"$LOG_FILE" 2>&1
}

# Start the background task
run_post_start_commands &

# Run the main process
echo "Starting the main process: $@"
exec "$@"
