// required_providers moved to providers.tf

provider "proxmox" {
  pm_api_url          = var.api_url
  pm_api_token_id     = var.token_id
  pm_api_token_secret = var.token_secret
  pm_tls_insecure     = true
}

locals {
  # Map of instances to create: one master + N workers
  workers = [for i in range(var.k8s_worker_count) : {
    name         = "k8s-worker-${i + 1}"
    proxmox_node = var.k8s_worker_node
    memory       = var.worker_memory
    cores        = var.worker_cores
  }]

  instances = merge(
    {
      "k8s-master" = {
        name         = "k8s-master"
        proxmox_node = var.k8s_master_node
        memory       = var.master_memory
        cores        = var.master_cores
      }
    },
    { for idx, w in local.workers : w.name => w }
  )
}

resource "proxmox_vm_qemu" "k8s_nodes" {
  for_each = local.instances

  name        = each.value.name
  target_node = each.value.proxmox_node
  # Prefer template VMID if provided, else use template name
  clone = var.template_vmid != null ? tostring(var.template_vmid) : var.template_name
  full_clone  = true

  agent   = 1
  os_type = "cloud-init"
  # provider v3: CPU config via cpu block
  cpu {
    sockets = 1
    cores   = each.value.cores
  }
  memory   = each.value.memory
  scsihw   = "virtio-scsi-pci"
  bootdisk = "scsi0"

  # provider v3 disks schema
  disks {
    scsi {
      scsi0 {
        disk {
          size       = "50G"
          storage    = var.storage_name
          emulatessd = true
          discard    = true
        }
      }
    }
  }

  network {
    id     = 0
    model  = "virtio"
    bridge = var.nic_name
    # Only set tag when a numeric VLAN is provided
    tag = can(regex("^\\d+$", tostring(var.vlan_num))) ? tonumber(tostring(var.vlan_num)) : null
  }

  lifecycle {
    ignore_changes = [network]
  }

  # Cloud-init settings
  # only pass sshkeys if the value looks like a valid public key
  sshkeys = can(regex("^ssh-(rsa|ed25519) ", var.ssh_key)) ? var.ssh_key : null
  ciuser  = var.ssh_user
  # Let DHCP assign IP (if your network uses DHCP); otherwise, set something like
  # ipconfig0 = "ip=192.168.1.100/24,gw=192.168.1.1"
  ipconfig0 = "ip=dhcp"
}

# Existing VM: manage state only, do not modify or destroy
# Real VM name and node from Proxmox

