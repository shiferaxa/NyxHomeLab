# NyxHomeLab

Home lab Kubernetes cluster built with kubeadm on two bare metal Ubuntu Server boxes, with Flux keeping the cluster in sync with this repo.

## Hosts

| Host   | Role          | LAN IP        | Notes                              |
|--------|---------------|---------------|------------------------------------|
| athena | control plane | 192.168.5.167 | 16 GB RAM, also schedules pods     |
| aries  | worker        | 192.168.5.166 | 32 GB RAM, carries most workloads  |

Both run Ubuntu 26.04 LTS, Kubernetes 1.36 (packages held), containerd 2.2 from the Ubuntu repo, and Cilium 1.20 as the CNI with pod CIDR 10.244.0.0/16. IPs are DHCP reservations on the router.

## Layout

```
docs/           Runbooks and architecture notes
kubernetes/     Flux GitOps tree (clusters, infrastructure, apps)
scripts/        Flux bootstrap
.github/        CI (kustomize build)
```

## Workflow

1. Build or rebuild the nodes by following docs/kubeadm-baremetal.md. Every command is run by hand over SSH.
2. Copy the kubeconfig from athena to the laptop and confirm `kubectl get nodes` shows both nodes Ready.
3. Run scripts/bootstrap-flux.sh to install Flux and point it at kubernetes/clusters/nyx.

After step 3 everything under kubernetes/ is reconciled by Flux. Commit a change and Flux applies it.

## Status

- [x] kubeadm cluster on bare metal (Sep 2026)
- [x] Cilium CNI, replaced the initial Flannel install (Sep 2026)
- [x] Flux bootstrap (Sep 2026, Flux 2.9.5)
- [ ] MetalLB, ingress-nginx, cert-manager
- [ ] Monitoring (kube-prometheus-stack)
- [ ] Tailscale on both nodes
