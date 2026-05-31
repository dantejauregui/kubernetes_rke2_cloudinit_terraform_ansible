terraform {

  required_providers {

    proxmox = {

      source = "bpg/proxmox"

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

  gateway = "192.168.0.1"

  cidr = "/24"

  vms = {

    cp1 = {

      vmid = 101

      hostname = "cp1"

      ip = "192.168.0.19"

      memory = 4096

      cores = 2

      disk = 40
    }

    worker2 = {

      vmid = 102

      hostname = "worker2"

      ip = "192.168.0.20"

      memory = 4096

      cores = 2

      disk = 30
    }

    worker1 = {

      vmid = 103

      hostname = "worker1"

      ip = "192.168.0.21"

      memory = 4096

      cores = 4

      disk = 40
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

  stop_on_destroy = false

  clone {

    vm_id = 998

    full = false
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

    upgrade = false

    ip_config {

      ipv4 {

        address = "${each.value.ip}${local.cidr}"

        gateway = local.gateway
      }
    }

    user_account {

      username = "ubuntu"

      keys = [

        trimspace(file("~/.ssh/id_ed25519.pub"))
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

  vga {

    type = "serial0"
  }
}
