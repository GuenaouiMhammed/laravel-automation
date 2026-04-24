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

  #Deployment

  provisioner "remote-exec" {
  inline = [
    # wait for VM ready
    "while [ ! -f /var/lib/cloud/instance/boot-finished ]; do sleep 5; done",

    # DNS fix
    "echo 'nameserver 8.8.8.8' > /etc/resolv.conf",
    "echo 'nameserver 1.1.1.1' >> /etc/resolv.conf",

    # install git
    "apt update && apt install -y git",

    # clone project
    "rm -rf /opt/laravel",
    "git clone https://github.com/GuenaouiMhammed/laravel-automation.git /opt/laravel",

    # prepare env
    "cp /opt/laravel/app/.env.example /opt/laravel/app/.env",

    # fix DB config INSIDE container (this is the real fix)
"docker exec laravel_app bash -c \"sed -i 's/DB_CONNECTION=.*/DB_CONNECTION=mysql/' /var/www/.env\"",
"docker exec laravel_app bash -c \"sed -i 's/DB_HOST=.*/DB_HOST=db/' /var/www/.env\"",
"docker exec laravel_app bash -c \"sed -i 's/DB_PORT=.*/DB_PORT=3306/' /var/www/.env\"",
"docker exec laravel_app bash -c \"sed -i 's/DB_DATABASE=.*/DB_DATABASE=laravel/' /var/www/.env\"",
"docker exec laravel_app bash -c \"sed -i 's/DB_USERNAME=.*/DB_USERNAME=root/' /var/www/.env\"",
"docker exec laravel_app bash -c \"sed -i 's/DB_PASSWORD=.*/DB_PASSWORD=root/' /var/www/.env\"",

    # go to project
    "cd /opt/laravel",

    # start containers
    "docker compose up -d --build",

    # wait for containers (IMPORTANT)
    "sleep 20",

    # install dependencies
    "docker exec laravel_app bash -c 'cd /var/www && composer install'",

    # generate key
    "docker exec laravel_app bash -c 'cd /var/www && php artisan key:generate'",

    "docker exec laravel_app bash -c \"sed -i 's/DB_HOST=.*/DB_HOST=db/' /var/www/.env\"",

    # ✅ FIX PERMISSIONS (CORRECT PATH)
    "docker exec laravel_app bash -c 'cd /var/www && chmod -R 777 storage bootstrap/cache'",

    # run migrations
    "docker exec laravel_app bash -c 'cd /var/www && php artisan migrate --force || true'",

    # clear caches (extra safety)
    "docker exec laravel_app bash -c 'cd /var/www && php artisan config:clear && php artisan cache:clear'",

    # debug
    "docker ps",

    "docker exec laravel_app bash -c 'chmod -R 775 /var/www/storage /var/www/bootstrap/cache'"
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