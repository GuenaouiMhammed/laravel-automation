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
    "while [ ! -f /var/lib/cloud/instance/boot-finished ]; do sleep 5; done",

    "echo 'nameserver 8.8.8.8' > /etc/resolv.conf",
    "echo 'nameserver 1.1.1.1' >> /etc/resolv.conf",

    "apt update && apt install -y git",

    "rm -rf /opt/laravel",
    "git clone https://github.com/GuenaouiMhammed/laravel-automation.git /opt/laravel",

    # use your committed .env OR create clean one
    "cp /opt/laravel/app/.env.example /opt/laravel/app/.env",

    "cd /opt/laravel",

    # prepare env BEFORE starting containers
"cp /opt/laravel/app/.env.example /opt/laravel/app/.env",

# force DB config (NO COMMENTS)
"sed -i 's/^DB_CONNECTION=.*/DB_CONNECTION=mysql/' /opt/laravel/app/.env",
"sed -i 's/^#* *DB_HOST=.*/DB_HOST=db/' /opt/laravel/app/.env",
"sed -i 's/^#* *DB_PORT=.*/DB_PORT=3306/' /opt/laravel/app/.env",
"sed -i 's/^#* *DB_DATABASE=.*/DB_DATABASE=laravel/' /opt/laravel/app/.env",
"sed -i 's/^#* *DB_USERNAME=.*/DB_USERNAME=root/' /opt/laravel/app/.env",
"sed -i 's/^#* *DB_PASSWORD=.*/DB_PASSWORD=root/' /opt/laravel/app/.env",

# THEN start containers
"docker compose up -d --build",

    "sleep 20",

    "docker exec laravel_app npm install",
    "docker exec laravel_app npm run build",

    # clear cache properly
    "docker exec laravel_app rm -f /var/www/bootstrap/cache/config.php",
    "docker exec laravel_app php artisan config:clear",

    "docker exec laravel_app php artisan key:generate --force",

    # run migrations
    "docker exec laravel_app php artisan migrate --force",
    

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