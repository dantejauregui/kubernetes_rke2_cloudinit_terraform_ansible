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
      vmid   = 101
      memory = 2048
    }

    cp2 = {
      vmid   = 102
      memory = 2048
    }
  }

  vmid        = each.value.vmid
  name        = each.key
  target_node = "proxmox"

  clone = "ubuntu-2404-template"

  full_clone = false

  onboot = true

  agent = 1

  os_type = "cloud-init"

  scsihw = "virtio-scsi-single"

  boot = "order=scsi0"

  cores   = 2
  sockets = 1
  vcpus   = 2

  memory = each.value.memory

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
          size    = "20G"
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
