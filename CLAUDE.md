# NyxHomeLab

Home lab Kubernetes cluster. Two Ubuntu 26.04 Server boxes on the LAN, athena (192.168.5.167, control plane, 16 GB) and aries (192.168.5.166, worker, 32 GB), built with kubeadm on bare metal, with Flux for GitOps.

## Warnings

- The user runs every command on athena and aries themselves over SSH. Give commands with the why, never execute them. Every step in a walkthrough carries its exact command.
- Paste one block at a time on the nodes. apt-get install swallows the rest of a pasted block from stdin.
- Ubuntu 26.04 ships containerd 2.x (pause image key is `sandbox`, not `sandbox_image`) and Rust uutils coreutils, so errors read like "(os error 2)".
- kubeconfig and admin.conf are gitignored. Never commit them. The repo is public.

## Architecture

Bare metal, no hypervisor. Kubernetes 1.36 (apt packages held), containerd 2.2, Flannel with pod CIDR 10.244.0.0/16. Control plane endpoint 192.168.5.167:6443. athena is untainted so it schedules pods too. See docs/architecture.md.

- docs/kubeadm-baremetal.md: the build runbook, step by step, both nodes
- docs/architecture.md: components, network, open decisions
- kubernetes/clusters/nyx: Flux entry point (infrastructure then apps Kustomizations)
- kubernetes/infrastructure/controllers: namespaces, later MetalLB, ingress-nginx, cert-manager
- kubernetes/infrastructure/configs: IP pools and ClusterIssuers that depend on controller CRDs
- kubernetes/apps: workloads
- scripts/bootstrap-flux.sh: flux bootstrap github against this repo, needs GITHUB_TOKEN
- .github/workflows/ci.yml: kustomize build of every tree

## Commands

```
kubectl get nodes -o wide            # from WSL, config copied from athena ~/.kube/config
kubectl kustomize kubernetes/apps    # same check CI runs
GITHUB_TOKEN=... ./scripts/bootstrap-flux.sh
```

## Conventions

- No em dashes or double hyphens in docs or commit messages. No AI or Claude mentions anywhere.
- Kubernetes minor is pinned in docs/kubeadm-baremetal.md step 4. Upgrade by changing the apt repo path and following the kubeadm upgrade docs, never by unholding packages.

## Current state

- Sep 13 2026: cluster built and smoke tested (cross node pod to service via CoreDNS). IPs reserved on the eero (app only, no web UI). Proxmox and Terraform design removed from the repo.
- Flux is NOT bootstrapped yet. Nothing under kubernetes/ is applied to the cluster.
- Not done: Flux bootstrap, Tailscale on the nodes, MetalLB, ingress, cert-manager, monitoring.
- Next step: run scripts/bootstrap-flux.sh, then uncomment metallb in kubernetes/infrastructure/controllers/kustomization.yaml and add the manifests.
