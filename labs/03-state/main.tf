terraform {
  required_providers {
    local  = { source = "hashicorp/local", version = ">= 2.4.0" }
    random = { source = "hashicorp/random", version = ">= 3.5.0" }
  }
}

# State lab: kaynakları oluşturduktan sonra state komutlarını dene

resource "random_pet" "sunucu_adi" {
  length    = 2
  separator = "-"
}

resource "random_integer" "port" {
  min = 8000
  max = 9000
}

resource "local_file" "sunucu_config" {
  filename = "${path.module}/cikti/sunucu.conf"
  content  = "server_name=${random_pet.sunucu_adi.id}\nport=${random_integer.port.result}\n"
}

resource "local_file" "env_dosya" {
  filename = "${path.module}/cikti/.env"
  content  = "APP_NAME=${random_pet.sunucu_adi.id}\nAPP_PORT=${random_integer.port.result}\n"
}

# LAB GÖREVLERİ (apply sonrası çalıştırın):
#
#   terraform state list
#   terraform state show random_pet.sunucu_adi
#   terraform state show local_file.sunucu_config
#   terraform output   (boş — henüz output tanımlamadık)
#
# Deneyin:
#   terraform state rm local_file.env_dosya
#   terraform state list       # env_dosya artık listede yok
#   terraform plan             # Terraform onu "yeni kaynak" zanneder
#   terraform state list -id=<id>
