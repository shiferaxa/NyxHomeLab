// Example terraform.tfvars (safe to commit). Put secrets in secrets.tfvars (ignored).
// Fill these values for your environment.

api_url       = "https://athena.rohu-atria.ts.net:8006/api2/json"
template_name = "ubuntu-2404-template"
storage_name  = "terrablock" // Proxmox storage backing TrueNAS iSCSI
nic_name      = "vmbr0"
// vlan_num   = 123            // uncomment to tag VLAN

ssh_user = "ubuntu"
// ssh_key  = "ssh-ed25519 AAAAC3... user@host" // paste your public key, or leave unset to skip

k8s_master_node  = "athena"
k8s_worker_node  = "aries"
k8s_worker_count = 4
master_memory    = 4096
worker_memory    = 2048
master_cores     = 2
worker_cores     = 2