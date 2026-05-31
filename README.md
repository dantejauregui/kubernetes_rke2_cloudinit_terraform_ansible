# Proxmox + Terraform + Cloud-Init Lab

Phase 1 — Terraform Infrastructure
----------------------------------
Proxmox VMs
Cloud-init
Networking
Disks
IPs

Phase 2 — Ansible Bootstrap
---------------------------
OS prep
RKE2 install
Join nodes
Fetch kubeconfig
Cluster baseline only

Phase 3 — Platform Terraform
----------------------------
MetalLB
Gateway API CRDs
Envoy Gateway
cert-manager
ArgoCD
Observability
Apps

Phase 4 — GitOps / Applications
-------------------------------
Namespaces
Applications
Helm releases
Manifests

---

# Architecture

Terraform clones lightweight Ubuntu cloud-init templates from Proxmox.

VM customization is injected dynamically through:
- cloud-init
- DHCP
- SSH key injection

Template remains:
- generic
- minimal
- reusable

---

# Requirements

## Proxmox VE
Recommended:
- Proxmox VE 9.x

## Terraform
Recommended:
- Terraform >= 1.8

## Ubuntu Template
Template OS:
- Ubuntu 24.04 LTS

---

# PHASE 1 — Create Ubuntu Template

Run ALL commands on the Proxmox node shell.

---

## 1. Download Ubuntu ISO

```bash
cd /var/lib/vz/template/iso

wget https://releases.ubuntu.com/noble/ubuntu-24.04.4-live-server-amd64.iso
```

---

## 2. Create VM

```bash
qm create 9000 \
  --name ubuntu-2404-template \
  --memory 2048 \
  --cores 2 \
  --cpu host \
  --net0 virtio,bridge=vmbr0
```

---

## 3. Add disk

```bash
qm set 9000 \
  --scsi0 local-lvm:20
```

---

## 4. Attach Ubuntu ISO

```bash
qm set 9000 \
  --ide0 local:iso/ubuntu-24.04.4-live-server-amd64.iso,media=cdrom
```

---

## 5. Configure boot order

```bash
qm set 9000 --boot order='ide0;scsi0'
```

---

## 6. Start VM

```bash
qm start 9000
```

Open:
- Proxmox UI
- VM 9000
- Console

Follow Ubuntu installer steps.

IMPORTANT:
- Install OpenSSH server
- Enable password authentication
- Do NOT install additional snaps/packages

---

# BEFORE CLICKING "REBOOT NOW"

Remove installer ISO:

```bash
qm set 9000 --delete ide0
```

Then continue reboot from installer UI.

---

# PHASE 2 — Prepare Cloud-Init Template

After Ubuntu boots successfully:

---

## 1. Add cloud-init drive

```bash
qm set 9000 --ide2 local-lvm:cloudinit
```

---

## 2. Configure boot order

```bash
qm set 9000 --boot order='scsi0;ide2'
```

---

## 3. Configure serial console

```bash
qm set 9000 --serial0 socket
qm set 9000 --vga serial0
```

---

## 4. Login to Ubuntu VM

Install required packages:

```bash
sudo apt update

sudo apt install \
  qemu-guest-agent \
  cloud-init \
  openssh-server \
  -y
```

---

## 5. Enable services

```bash
sudo systemctl enable --now qemu-guest-agent
sudo systemctl enable ssh
```

---

## 6. Validate qemu guest agent

Run from Proxmox node:

```bash
qm guest exec 9000 -- ip a
```

Expected:
- successful command output
- VM IP visible

---

# PHASE 3 — Clean Template Identity

Run INSIDE Ubuntu VM.

---

## 1. Clean cloud-init state

```bash
sudo cloud-init clean
```

---

## 2. Remove machine identity

```bash
sudo truncate -s 0 /etc/machine-id
```

IMPORTANT:
This allows cloned VMs to generate unique machine IDs.

---

## 3. Clean apt cache

```bash
sudo apt clean
```

---

## 4. Shutdown VM

```bash
sudo shutdown now
```

---

# PHASE 4 — Convert VM to Template

Run on Proxmox node:

```bash
qm template 9000
```

Verify:
- VM icon changes to template icon in Proxmox UI

---

# Create Proxmox API Token

In Proxmox UI:

Datacenter
→ Permissions
→ API Tokens

Create:
- User: root@pam
- Token ID: terraform
- Privilege Separation: unchecked

Save:
- token ID
- token secret

IMPORTANT:
Secret is shown only once.

---

# SSH Key Setup

Terraform injects SSH public keys through cloud-init.

Verify local SSH public key exists:

```bash
cat ~/.ssh/id_ed25519.pub
```

If missing:

```bash
ssh-keygen -t ed25519
```

---

# Terraform Workflow

## Initialize provider

```bash
terraform init -upgrade
```

---

## Validate configuration

```bash
terraform validate
```

---

## Preview infrastructure

```bash
terraform plan
```

---

## Create infrastructure

```bash
terraform apply
```

---

## Destroy infrastructure

```bash
terraform destroy
```

---

# Validation Checklist

After Terraform apply:

- VM boots successfully
- DHCP IP assigned
- SSH works
- cloud-init hostname applied
- unique machine-id generated
- qemu-agent working
- Proxmox shows VM IP

---

# Current Design Decisions

## DHCP instead of static IPs

Reason:
- simpler lifecycle
- easier reprovisioning
- closer to cloud workflows

Future improvement:
- DHCP reservations on router

---

## Linked clones instead of full clones

```hcl
full_clone = false
```

Reason:
- saves HDD space
- faster provisioning
- sufficient for homelab

---

# Future Roadmap

Planned:
- Multi-node Terraform orchestration
- K3s cluster bootstrap
- HA control plane
- ArgoCD
- PostgreSQL HA
- Keycloak
- Ingress controller
- GitOps workflows


# Terraform steps to create Proxmox VMs:
terraform init
terraform plan
terraform apply


# Ansible steps for configuration of VMs:
ansible-playbook playbooks/common.yml

ansible-playbook playbooks/rke2-server.yml

ansible-playbook playbooks/rke2-workers.yml

ansible-playbook playbooks/fetch-kubeconfig.yml


After fetching the kubeconfig inside the Ansible's Artifact folder, export it and now you can use "k9s":

export KUBECONFIG=artifacts/rke2.yaml
kubectl get nodes
k9s
