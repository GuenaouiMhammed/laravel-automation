terraform {
  required_providers {
    proxmox = {
      source  = "bpg/proxmox"
      version = "0.46.0"
    }
  }
}

############################
# VARIABLES
############################

variable "pm_api_token" {
  default = "guenaoui@pve!terraform-token=1f39bdd4-78c3-411d-9fa2-c77e8836f888"
}

variable "vm_ip" {
  default = "172.16.32.65"   # ✅ UPDATED IP
}

############################
# PROVIDER
############################

provider "proxmox" {
  endpoint  = "https://172.16.32.204:8006"
  api_token = var.pm_api_token
  insecure  = true
}

############################
# VM RESOURCE
############################

resource "proxmox_virtual_environment_vm" "laravel_vm" {
  name      = "laravel-production"
  node_name = "ucdpve"

  clone {
    vm_id = 113
  }

  cpu {
    cores = 4
  }

  memory {
    dedicated = 8192
  }

  network_device {
    bridge = "vmbr0"
  }

  ################################
  # CLOUD-INIT
  ################################
  initialization {
    ip_config {
      ipv4 {
        address = "${var.vm_ip}/24"
        gateway = "172.16.32.1"
      }
    }

    user_account {
      username = "root"
      password = "flash"
    }
  }

  ################################
  # SSH CONNECTION
  ################################
  connection {
    type     = "ssh"
    user     = "root"
    password = "flash"
    host     = var.vm_ip
    timeout  = "10m"
  }

  ################################
  # WAIT FOR CLOUD INIT
  ################################
  provisioner "remote-exec" {
    inline = [
      "while [ ! -f /var/lib/cloud/instance/boot-finished ]; do sleep 5; done",
      "echo 'nameserver 8.8.8.8' > /etc/resolv.conf",
      "echo 'nameserver 1.1.1.1' >> /etc/resolv.conf",
      "mkdir -p /opt/laravel"
    ]
  }

  ################################
  # FILE UPLOAD (UPDATED)
  ################################
  provisioner "file" {
    source      = "app"   # ✅ your Laravel folder
    destination = "/opt/laravel/app"
  }

provisioner "file" {
  source      = "Dockerfile"
  destination = "/opt/laravel/Dockerfile"
}

  provisioner "file" {
    source      = "docker-compose.yml"
    destination = "/opt/laravel/docker-compose.yml"
  }

  provisioner "file" {
    source      = "nginx.conf"
    destination = "/opt/laravel/nginx.conf"
  }

  ################################
  # DEPLOY (UPDATED)
  ################################
  provisioner "remote-exec" {
    inline = [
      "cd /opt/laravel",
      "docker compose down 2>/dev/null || true",
      "docker compose up -d",
      "sleep 10",

      # Laravel fixes
      "docker exec laravel_app chmod -R 777 storage bootstrap/cache || true",
      "docker exec laravel_app php artisan migrate --force || true",

      "docker ps"
    ]
  }
}

############################
# OUTPUTS
############################

output "app_url" {
  value = "http://${var.vm_ip}"
}

output "ssh" {
  value = "ssh root@${var.vm_ip}"
}