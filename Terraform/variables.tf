# Set your public SSH key here (ssh-ed25519 or ssh-rsa). Leave empty to skip injecting keys.
variable "ssh_key" {
  description = "SSH public key for cloud-init (ssh-ed25519 or ssh-rsa). Leave empty to skip."
  type        = string
  default     = ""
}
#Specify which template name you'd like to use
variable "template_name" {
  default = "ubuntu-2404-template"
}

# Optional: specify the template VMID directly (overrides template_name)
variable "template_vmid" {
  description = "Proxmox VMID of the template to clone from; takes precedence over template_name when set"
  type        = number
  default     = null
}
#Establish which nic you would like to utilize
variable "nic_name" {
  default = "vmbr0"
}
#Establish the VLAN you'd like to use
variable "vlan_num" {
  description = "VLAN tag number to apply to VM NIC. Use null to skip VLAN tagging."
  type        = number
  default     = null
}
#Provide the url of the host you would like the API to communicate on.
#It is safe to default to setting this as the URL for what you used
#as your `proxmox_host`, although they can be different
variable "api_url" {
  description = "Proxmox API base URL including /api2/json"
  default     = "https://athena.rohu-atria.ts.net:8006/api2/json"
}
#Blank var for use by terraform.tfvars
variable "token_secret" {
}
#Blank var for use by terraform.tfvars
variable "token_id" {
}

# Kubernetes deployment defaults
variable "k8s_master_node" {
  description = "Proxmox host to place the Kubernetes master node on"
  default     = "aries"
}

variable "k8s_worker_node" {
  description = "Proxmox host to place Kubernetes worker nodes on"
  default     = "athena"
}

variable "k8s_worker_count" {
  description = "Number of Kubernetes worker nodes to create"
  default     = 2
}

variable "master_memory" {
  description = "Memory (MB) for the k8s master VM"
  default     = 4096
}

variable "worker_memory" {
  description = "Memory (MB) for k8s worker VMs"
  default     = 2048
}

variable "master_cores" {
  description = "vCPU cores for the k8s master VM"
  default     = 2
}

variable "worker_cores" {
  description = "vCPU cores for k8s worker VMs"
  default     = 2
}

# Optional: cloud-init SSH user (varies by template; Ubuntu images typically use "ubuntu")
variable "ssh_user" {
  description = "Default SSH user configured via cloud-init"
  default     = "ubuntu"
}

# Optional: storage name for disks
variable "storage_name" {
  description = "terrablock"
  default     = "intel-storage"
}