FROM public.ecr.aws/amazonlinux/amazonlinux:2023

RUN dnf -y update \
    && dnf -y install systemd runc containerd docker iptables nftables socat conntrack ethtool tar vi procps kmod \
    && dnf clean all
    
RUN cd /lib/systemd/system/sysinit.target.wants/; \
    for i in *; do [ $i = systemd-tmpfiles-setup.service ] || rm -f $i; done

RUN rm -f /lib/systemd/system/multi-user.target.wants/* \
    /etc/systemd/system/*.wants/* \
    /lib/systemd/system/local-fs.target.wants/* \
    /lib/systemd/system/sockets.target.wants/*udev* \
    /lib/systemd/system/sockets.target.wants/*initctl* \
    /lib/systemd/system/basic.target.wants/* \
    /lib/systemd/system/anaconda.target.wants/*

# Copy nodeConfig to /usr/local/bin/
COPY ["nodeConfig.yaml", "entrypoint.sh", "setup-overlay.sh", "update-containerd.sh", "/usr/local/bin/"]

COPY 10-kindnet.conflist /etc/cni/net.d/10-kindnet.conflist

# Download and install nodeadm
RUN curl -OL 'https://hybrid-assets.eks.amazonaws.com/releases/latest/bin/linux/amd64/nodeadm' \
    && chmod +x nodeadm \
    && mv nodeadm /usr/local/bin/ \
    && chmod +x /usr/local/bin/entrypoint.sh

# Download and install crictl for local debugging
ENV VERSION="v1.32.0"
RUN curl -OL https://github.com/kubernetes-sigs/cri-tools/releases/download/${VERSION}/crictl-${VERSION}-linux-amd64.tar.gz \
    && tar -C /usr/local/bin -xzf crictl-${VERSION}-linux-amd64.tar.gz \
    && rm crictl-${VERSION}-linux-amd64.tar.gz

# Create mock overlay filesystem
RUN mkdir -p /mnt/tmpfs

# Expose the kubelet port
EXPOSE 10250

# systemd exits on SIGRTMIN+3, not SIGTERM (which re-executes it)
# https://bugzilla.redhat.com/show_bug.cgi?id=1201657
STOPSIGNAL SIGRTMIN+3

# Set the ENTRYPOINT to the script
ENTRYPOINT ["/usr/local/bin/entrypoint.sh"]

# Set default command to systemd
CMD ["/sbin/init"]