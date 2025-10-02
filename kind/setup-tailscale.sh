#!/bin/bash
# This script configures Tailscale to connect the EKS hybrid node to the cluster
# NOTE: Currently commented out due to network access issues to Tailscale

# Usage: setup-tailscale.sh [authkey]
# If authkey isn't provided as argument, the script will prompt for it

# AUTH_KEY="$1"

# NOTE: All functionality below is commented out due to network access issues

# # Function to get auth key if not provided
# get_auth_key() {
#   if [ -z "$AUTH_KEY" ]; then
#     echo "Enter your Tailscale auth key:"
#     read -r AUTH_KEY
#   fi
# }
#
# # Start Tailscale daemon
# start_tailscaled() {
#   echo "Starting tailscaled service..."
#   systemctl start tailscaled
#   systemctl status tailscaled --no-pager
# }
#
# # Connect to Tailscale network
# connect_to_tailscale() {
#   echo "Connecting to Tailscale network..."
#   # Use machine hostname for Tailscale name
#   HOSTNAME=$(hostname)
#
#   tailscale up --authkey="$AUTH_KEY" \
#     --hostname="$HOSTNAME" \
#     --accept-dns=false
#
#   # Check if connected successfully
#   if tailscale status > /dev/null 2>&1; then
#     echo "Successfully connected to Tailscale network"
#     return 0
#   else
#     echo "Failed to connect to Tailscale network"
#     return 1
#   fi
# }
#
# # Find EKS control plane in Tailscale network
# find_eks_control_plane() {
#   echo "Looking for EKS control plane in Tailscale network..."
#   tailscale status
#
#   # Try to find the EKS API server by name pattern
#   EKS_IP=$(tailscale status 2>/dev/null | grep -i eks | awk '{print $1}')
#   if [ -n "$EKS_IP" ]; then
#     echo "Found EKS control plane at: $EKS_IP"
#     # Export the IP for use in other scripts
#     echo "export CLUSTER_ENDPOINT=https://$EKS_IP" > /etc/eks/tailscale-cluster-endpoint
#     return 0
#   else
#     echo "Could not find EKS control plane in Tailscale network"
#     return 1
#   fi
# }
#
# # Main execution
# echo "Setting up Tailscale for EKS hybrid node..."
# get_auth_key
# start_tailscaled
# if connect_to_tailscale; then
#   find_eks_control_plane
#   echo "Tailscale setup completed"
# else
#   echo "Tailscale setup failed"
#   exit 1
# fi

# Alternative method without Tailscale
# echo "Skipping Tailscale setup due to network access issues"
# echo "Using direct connection to EKS API server"

# Future enhancement: Add alternative networking method here
# For now, the container will use the default 10.0.0.1 endpoint