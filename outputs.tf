output "vm_names" {
  value = {
    for k, vm in proxmox_vm_qemu.ubuntu_vm :
    k => vm.name
  }
}

output "vm_ids" {
  value = {
    for k, vm in proxmox_vm_qemu.ubuntu_vm :
    k => vm.vmid
  }
}

output "vm_ips" {
  value = {
    for k, vm in proxmox_vm_qemu.ubuntu_vm :
    k => vm.default_ipv4_address
  }
}
