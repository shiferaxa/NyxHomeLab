# NyxHomeLab

Infrastructure as code for my home lab. Two Proxmox hosts (athena and aries) reachable over Tailscale, a kubeadm Kubernetes cluster built from cloud-init VMs, and Flux keeping the cluster in sync with this repo.

## Layout

```
Terraform/      Proxmox VMs for the k8s cluster (telmate/proxmox provider)
ansible/        Bootstraps the VMs into a kubeadm cluster
kubernetes/     Flux GitOps tree (clusters, infrastructure, apps)
scripts/        Helper scripts for plan/apply and Flux bootstrap
docs/           Architecture notes and runbooks
.github/        CI checks (terraform fmt/validate, kustomize build)
```

## Hosts

| Host   | Role                       | Notes                           |
|--------|----------------------------|---------------------------------|
| athena | Proxmox, k8s worker VMs    | API at athena.rohu-atria.ts.net |
| aries  | Proxmox, k8s control plane |                                 |

## Workflow

1. Copy Terraform/terraform.tfvars.example to terraform.tfvars and put the API token in Terraform/secrets.tfvars (gitignored).
2. Run ./scripts/tf.sh plan, then ./scripts/tf.sh apply to create the VMs.
3. Run ./scripts/tf.sh output k8s_nodes and fill ansible/inventory/hosts.yml from hosts.yml.example.
4. Run ansible-playbook ansible/playbooks/site.yml to install containerd, kubeadm, and join the nodes.
5. Run ./scripts/bootstrap-flux.sh to install Flux and point it at kubernetes/clusters/nyx.

After step 5 everything under kubernetes/ is reconciled by Flux. Commit a change and Flux applies it.

## Status

- [x] Terraform for Proxmox VMs
- [ ] Ansible kubeadm bootstrap (k8s_node role still a stub)
- [ ] Flux bootstrap
- [ ] MetalLB, ingress-nginx, cert-manager
- [ ] Monitoring (kube-prometheus-stack)
- [ ] Remote Terraform state
