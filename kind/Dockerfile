FROM kindest/node:v1.31.12
# Install EKS hybrid node components
RUN apt-get update && apt-get install -y curl gpg

# # Add Tailscale repository and install - commented out due to network access issues
# RUN curl -fsSL https://tailscale.com/install.sh | sh

# Download and install nodeadm
RUN curl -OL 'https://hybrid-assets.eks.amazonaws.com/releases/latest/bin/linux/arm64/nodeadm' \
    && chmod +x nodeadm \
    && mv nodeadm /usr/local/bin/

# Copy configuration files
COPY ["nodeConfig.yaml", "entrypoint.sh", "hybrid-node-setup.service", "hybrid-node-setup.sh", "setup-tailscale.sh", "/usr/local/bin/"]
RUN chmod +x /usr/local/bin/entrypoint.sh /usr/local/bin/hybrid-node-setup.sh 
# /usr/local/bin/setup-tailscale.sh

# Expose the kubelet port
EXPOSE 10250

ENTRYPOINT ["/usr/local/bin/entrypoint.sh"]
CMD ["/sbin/init"]