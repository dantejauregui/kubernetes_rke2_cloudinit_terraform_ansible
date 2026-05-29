terraform {
  required_providers {
    proxmox = {
      source  = "bpg/proxmox"
      version = "~> 0.78"
    }
  }
}

provider "proxmox" {

  endpoint = var.proxmox_api_url

  api_token = "${var.proxmox_api_token_id}=${var.proxmox_api_token_secret}"

  insecure = true
}

locals {

  vms = {

    cp1 = {
      vmid     = 101
      hostname = "cp1"

      memory = 4096
      cores  = 2
      disk   = 40
    }

    worker1 = {
      vmid     = 103
      hostname = "worker1"

      memory = 4096
      cores  = 4
      disk   = 40
    }

    worker2 = {
      vmid     = 102
      hostname = "worker2"

      memory = 4096
      cores  = 2
      disk   = 30
    }
  }
}

resource "proxmox_virtual_environment_vm" "ubuntu_vm" {

  for_each = local.vms

  node_name = "proxmox"

  vm_id = each.value.vmid

  name = each.value.hostname

  started = true

  on_boot = true

  clone {
    vm_id = 998
    full  = false
  }

  agent {
    enabled = true
  }

  cpu {

    cores = each.value.cores

    type = "host"
  }

  memory {

    dedicated = each.value.memory
  }

  disk {

    datastore_id = "local-lvm"

    interface = "scsi0"

    size = each.value.disk
  }

  initialization {

    datastore_id = "local-lvm"

    interface = "ide2"

    ip_config {

      ipv4 {

        address = "dhcp"
      }
    }

    user_account {

      username = "ubuntu"

      keys = [
        file("~/.ssh/id_ed25519.pub")
      ]
    }
  }

  network_device {

    bridge = "vmbr0"

    model = "virtio"
  }

  serial_device {}

  operating_system {

    type = "l26"
  }
}
