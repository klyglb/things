# main.tf

terraform {
  required_version = ">= 0.12"

  required_providers {
    libvirt = {
      source  = "dmacvicar/libvirt"
      version = "~> 0.7.6"
    }
    local = {
      source  = "hashicorp/local"
      version = "~> 2.1"
    }
  }
}

provider "libvirt" {
  uri = "qemu:///system"
}

variable "vm_names" {
  default = ["master", "worker1", "worker2"]
}

variable "base_image_file" {
  default = "AlmaLinux-9-GenericCloud-9.4-20240507.x86_64.qcow2"
}

# Создание сети default через Terraform
resource "libvirt_network" "default" {
  name      = "default"
  mode      = "nat"
  addresses = ["192.168.122.0/24"]  # Задайте сеть в формате CIDR

  dhcp {
    enabled = true
  }

  dns {
    enabled    = true
    local_only = true
  }

  autostart = true
}


# Создание базового образа
resource "libvirt_volume" "base_image" {
  name   = "base_image.qcow2"
  pool   = "default"
  source = var.base_image_file
  format = "qcow2"
}

# Создание дисков для ВМ на основе базового образа
resource "libvirt_volume" "vm_disks" {
  count          = length(var.vm_names)
  name           = "${var.vm_names[count.index]}.qcow2"
  pool           = "default"
  base_volume_id = libvirt_volume.base_image.id
  format         = "qcow2"
}

# Создание виртуальных машин
resource "libvirt_domain" "vm" {
  count  = length(var.vm_names)
  name   = var.vm_names[count.index]
  memory = 8192  # 8GB RAM
  vcpu   = 2

#  firmware = "/usr/share/edk2-ovmf/x64/OVMF_CODE.fd"

#  nvram {
#    file = "/var/lib/libvirt/nvram/${var.vm_names[count.index]}_VARS.fd"
#    template = "/usr/share/edk2-ovmf/x64/OVMF_VARS.4m.fd"
#  }

  disk {
    volume_id = libvirt_volume.vm_disks[count.index].id
#    scsi      = true  # Включение SCSI-контроллера, без этого и без переключения с БИОСа на UEFI тачка может виснуть на этапе инициализации
  }

  network_interface {
    network_id     = libvirt_network.default.id
    hostname       = var.vm_names[count.index]
    wait_for_lease = true
  }

  console {
    type        = "pty"
    target_type = "serial"
    target_port = "0"
  }

  graphics {
    type        = "spice"
    listen_type = "none"
  }

  autostart = true
}

# Генерация инвентарного файла Ansible
resource "local_file" "ansible_inventory" {
  content = templatefile("${path.module}/inventory.tpl", {
    vm_ips   = { for vm in libvirt_domain.vm : vm.name => vm.network_interface[0].addresses[0] },
    vm_names = [ for vm in libvirt_domain.vm : vm.name ],
  })
  filename = "${path.module}/ansible/inventory.ini"
}


