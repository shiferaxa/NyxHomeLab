output "k8s_nodes" {
  description = "Name, Proxmox node, and IP of each cluster VM"
  value = {
    for k, vm in proxmox_vm_qemu.k8s_nodes : k => {
      name = vm.name
      node = vm.target_node
      ip   = vm.default_ipv4_address
    }
  }
}

output "control_plane_ip" {
  description = "IP of the kubeadm control plane node"
  value       = proxmox_vm_qemu.k8s_nodes["k8s-master"].default_ipv4_address
}

output "worker_ips" {
  description = "IPs of the worker nodes"
  value       = [for k, vm in proxmox_vm_qemu.k8s_nodes : vm.default_ipv4_address if k != "k8s-master"]
}
