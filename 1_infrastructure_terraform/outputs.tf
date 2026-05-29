output "vm_names" {

  value = {

    for k, vm in proxmox_virtual_environment_vm.ubuntu_vm :

    k => vm.name
  }
}

output "vm_ids" {

  value = {

    for k, vm in proxmox_virtual_environment_vm.ubuntu_vm :

    k => vm.vm_id
  }
}

output "vm_ipv4" {

  value = {

    for k, vm in proxmox_virtual_environment_vm.ubuntu_vm :

    k => try(vm.ipv4_addresses[1][0], "unknown")
  }
}
