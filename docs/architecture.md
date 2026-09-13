# Architecture

## Physical

Two Ubuntu Server boxes on the home LAN (192.168.4.0/22, eero gateway). No hypervisor, Kubernetes runs directly on the hardware.

- athena: control plane (etcd, API server, scheduler, controller manager). Control plane taint removed so it also runs pods.
- aries: worker. Twice the RAM of athena, so it carries most workloads.

Both nodes have a single wired NIC (eno1). Tailscale is not installed yet.

## Cluster

- kubeadm, Kubernetes 1.36, apt packages held on both nodes
- containerd 2.2 with SystemdCgroup enabled (cgroup v2 on Ubuntu)
- Flannel VXLAN, pod CIDR 10.244.0.0/16
- Control plane endpoint is athena's LAN IP, 192.168.5.167:6443

## Provisioning flow

```
Manual kubeadm build (docs/kubeadm-baremetal.md)
   -> Flux bootstrap (GitRepository + Kustomizations)
      -> infrastructure/controllers (MetalLB, ingress, cert-manager)
      -> infrastructure/configs (IP pools, ClusterIssuers)
      -> apps
```

Flux reconciles in dependency order: controllers first, then configs that need their CRDs, then apps.

## Open decisions

- Secrets in git: SOPS with age is the plan
- Storage: local-path for now, decide on Longhorn or NFS later
- Whether to install Tailscale on the nodes for remote kubectl (needs the API server cert regenerated with the Tailscale name)
