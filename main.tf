terraform {
  required_providers {
    proxmox = {
      source  = "Telmate/proxmox"
      version = "3.0.2-rc07"
    }
  }
}

provider "proxmox" {
  pm_api_url          = var.proxmox_api_url
  pm_api_token_id     = var.proxmox_api_token_id
  pm_api_token_secret = var.proxmox_api_token_secret

  pm_tls_insecure = true
}

resource "proxmox_vm_qemu" "ubuntu_vm" {

  for_each = {

    cp1 = {
      vmid     = 101
      hostname = "cp1"

      memory  = 2048
      cores   = 2
      sockets = 1
      vcpus   = 2

      disk = "20G"
    }

    cp2 = {
      vmid     = 102
      hostname = "cp2"

      memory  = 2048
      cores   = 2
      sockets = 1
      vcpus   = 2

      disk = "20G"
    }

    worker1 = {
      vmid     = 103
      hostname = "worker1"

      memory  = 6144
      cores   = 4
      sockets = 1
      vcpus   = 4

      disk = "40G"
    }
  }

  vmid        = each.value.vmid
  name        = each.value.hostname
  target_node = "proxmox"

  clone = "ubuntu-2404-template"

  full_clone = false

  onboot = true

  agent = 1

  os_type = "cloud-init"

  scsihw = "virtio-scsi-single"

  boot = "order=scsi0"

  memory  = each.value.memory
  cores   = each.value.cores
  sockets = each.value.sockets
  vcpus   = each.value.vcpus

  serial {
    id   = 0
    type = "socket"
  }

  vga {
    type = "serial0"
  }

  network {
    id     = 0
    model  = "virtio"
    bridge = "vmbr0"
  }

  disks {
    scsi {
      scsi0 {
        disk {
          size    = each.value.disk
          storage = "local-lvm"
        }
      }
    }

    ide {
      ide2 {
        cloudinit {
          storage = "local-lvm"
        }
      }
    }
  }

  ipconfig0 = "ip=dhcp"

  ciuser = "ubuntu"

  sshkeys = file("~/.ssh/id_ed25519.pub")
}
