# Architecture

## Physical

Two Proxmox hosts joined by Tailscale so the API and SSH work from anywhere.

- athena: worker VMs, storage pool intel-storage
- aries: control plane VM

## Provisioning flow

```
Terraform (Proxmox VMs, cloud-init)
   -> Ansible (containerd, kubeadm init/join)
      -> Flux bootstrap (GitRepository + Kustomizations)
         -> infrastructure/controllers (MetalLB, ingress, cert-manager)
         -> infrastructure/configs (IP pools, ClusterIssuers)
         -> apps
```

Flux reconciles in dependency order: controllers first, then configs that need their CRDs, then apps.

## Open decisions

- Remote state for Terraform (S3 plus DynamoDB, or a MinIO bucket on the lab)
- Secrets in git: SOPS with age is the plan
- Whether to move the control plane to athena and free aries for other workloads
