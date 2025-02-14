# containerized-hybrid-node
This is the beginnings of a project to create a containerized version of an EKS hybrid node. It uses Amazon Linux 2023 as the parent container. The `entrypoint.sh` file runs a script that installs the prerequisites needed to run an EKS hybrid node including nodeadm which install various software components, creates configuration files from information retrieved from the cloud, and attempts to start different services such as the kubelet. The output of this script is saved to `/var/log/nodeadm_poststart_commands.log`. If you try this on your own, you may see errors in the log. Ignore these for now.

When you run `make run`, it will exec into the container automatically. Run the `setup-overlay.sh` script after the `entrypoint.sh` script is finished running. You may have to make it executable by running `chmod +x` first. This script will basically fool the container into thinking that it is using an overlay file system which is required for running nested containers. When that script has finished running, run the `update-containerd.sh` script next. This script will modify the containerd `config.toml` file to use the mock overlay file system. DO NOT re-run the `nodeadm init` command from hereon as this will overwrite the config.toml settings. The settings in the `update-container.sh` can and should be moved to the nodeConfig.yaml file, but I haven't had time to do that yet. 

At this stage, if you followed the other prerequisites for running hybrid nodes, you should see the container appear as a node in your cluster. It will be in a `Not Ready` state because it is unable to pull images from ECR (a problem I have yet to troubleshoot). 

### Update 2/5/2025
Calico and Cilium are both supported by Hyrbid nodes. Unfortunately, I couldn't get either of those CNIs to run as nested containers during my testing. I was able to get [Kindnet](https://kindnet.es/docs/) to work, however. The configuration file for kindnet is copied to `/etc/cni/net.d/` during the Docker build process. You will have to install Kindnet separately by running:

```bash
kubectl create -f https://raw.githubusercontent.com/aojea/kindnet/main/install-kindnet.yaml
```

> Note: if you previously installed a CNI, remove it before installing Kindnet. 

Right now, the containerd settings in the nodeConfig.yaml file are not being applied when nodeadm runs. These changes need to applied manually by running the `update-containerd.sh` script once nodeadm is finished running. After containerd is running, manually start the kubelet by running `systemctl start kubelet`. The node will join the cluster and appear as Ready shortly thereafter. While you will be able to schedule pods onto it, things like `kubectl logs` and `kubectl proxy` will not work. Since there is no direct network connectivity or route between the containerized hybrid node and instances in your VPC, pods that run on the containerized hybrid node will not be able to communicate the pods that run in the AWS cloud.  

I would welcome help from the community if you are interested in contributing to this project. 

### Troubleshooting
If the Kindnet pod fails to start because of disk pressure run `df -h` to see whether you're running low on disk space. If overlayfs is at or above 90% you may need to purge your cached images.

If you see errors like this: 
```
W0214 00:18:07.164384       1 reflector.go:569] pkg/mod/k8s.io/client-go@v0.32.1/tools/cache/reflector.go:251: failed to list *v1.NetworkPolicy: Get "https://10.0.0.1:443/apis/networking.k8s.io/v1/networkpolicies?limit=500&resourceVersion=0": dial tcp 10.0.0.1:443: i/o timeout
```
in the kindnet logs, you may need to add the KUBERNETES_SERVICE_HOST as an environment variable to the kindnet DaemonSet and set it to the URL of the public API endpoint. 

### Resources
- [kind/images/base/files/usr/local/bin/entrypoint at v0.26.0 · kubernetes-sigs/kind](https://github.com/kubernetes-sigs/kind/blob/v0.26.0/images/base/files/usr/local/bin/entrypoint)
- [eks-anywhere-build-tooling/projects/kubernetes-sigs/kind/build/build-kind-node-image.sh at main · aws/eks-anywhere-build-tooling](https://github.com/aws/eks-anywhere-build-tooling/blob/main/projects/kubernetes-sigs/kind/build/build-kind-node-image.sh)
- [eks-anywhere-build-tooling/projects/kubernetes-sigs/kind/patches/0001-Switch-to-AL2-base-image-for-node-image.patch at main · aws/eks-anywhere-build-tooling](https://github.com/aws/eks-anywhere-build-tooling/blob/main/projects/kubernetes-sigs/kind/patches/0001-Switch-to-AL2-base-image-for-node-image.patch)
- https://github.com/search?q=repo%3Aaws%2Feks-anywhere-build-tooling%20config.toml&type=code
- https://github.com/aws/eks-anywhere-build-tooling/blob/main/projects/kubernetes-sigs/kind/patches/0001-Switch-to-AL2-base-image-for-node-image.patch
