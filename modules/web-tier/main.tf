terraform {
  required_version = ">= 1.3.0"

  required_providers {
    huaweicloud = {
      source  = "huaweicloud/huaweicloud"
      version = ">= 1.60.0"
    }
  }
}

# Data Sources — mevcut bulut kaynaklarını sorgular

# Bölgedeki Availability Zone'ları listele
data "huaweicloud_availability_zones" "az" {}

# Ubuntu 22.04 imajını bul
data "huaweicloud_images_image" "ubuntu" {
  name        = "Ubuntu 22.04 server 64bit"
  most_recent = true
}

# ECS için uygun flavor bul (2 vCPU / 4 GB RAM)
# Eğer var.ecs_flavor dolu ise data source atlanır
data "huaweicloud_compute_flavors" "small" {
  availability_zone = data.huaweicloud_availability_zones.az.names[0]
  performance_type  = "normal"
  cpu_core_count    = 2
  memory_size       = 4
}

# Kullanılacak flavor ID'yi belirle:
# - Eğer kullanıcı elle belirtmişse onu kullan
# - Yoksa data source'dan otomatik seç
locals {
  flavor_id = var.ecs_flavor != "" ? var.ecs_flavor : data.huaweicloud_compute_flavors.small.ids[0]

  # Her ECS için hangi AZ kullanılacak (AZ sayısına göre döngüsel)
  az_list = data.huaweicloud_availability_zones.az.names

  # Silme koruması tarihi: tfvars'ta belirtilmişse onu kullan, yoksa bugünün tarihi
  time_tag = var.time_tag != "" ? var.time_tag : formatdate("YYYY-MM-DD", timestamp())
}
