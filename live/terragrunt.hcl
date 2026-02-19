# ===========================================================
# ROOT TERRAGRUNT KONFIGÜRASYONU
# ===========================================================
# Bu dosya live/ klasörünün kökündedir.
# Tüm ortamlar (dev, staging, prod) bu dosyayı "include" ederek
# provider ve remote state konfigürasyonunu miras alır.
#
# DRY PRENSİBİ:
# Provider ve backend'i bir kez yaz, her yerde kullan.
# ===========================================================

locals {
  # Kimlik bilgileri çevre değişkenlerinden okunur.
  # Hiçbir zaman bu dosyaya AK/SK yazmayın!
  #
  # Kullanım (terminal):
  #   export HW_ACCESS_KEY="sizin_access_key"
  #   export HW_SECRET_KEY="sizin_secret_key"
  access_key = get_env("HW_ACCESS_KEY", "")
  secret_key = get_env("HW_SECRET_KEY", "")

  # Varsayılan bölge — ortam bazında override edilebilir
  region = get_env("HW_REGION", "tr-west-1")

  # OBS bucket adı — terraform state dosyaları burada saklanır
  # Bu bucket'ı önceden oluşturmanız gerekir!
  # Örnek: workshop-tfstate-12345 (benzersiz olmalı)
  state_bucket = get_env("TG_STATE_BUCKET", "workshop-terragrunt-state")
}

# -----------------------------------------------------------
# GENERATE: provider.tf
# -----------------------------------------------------------
# Terragrunt, her modül klasöründe provider.tf dosyasını
# otomatik olarak oluşturur. Bu sayede provider bloğunu
# her modülde tekrar yazmak gerekmez.
#
# Terragrunt bu dosyayı .terragrunt-cache/ içine yazar,
# asıl kaynak koduna dokunmaz.

generate "provider" {
  path      = "provider.tf"
  if_exists = "overwrite_terragrunt"

  contents = <<EOF
provider "huaweicloud" {
  region     = "${local.region}"
  access_key = "${local.access_key}"
  secret_key = "${local.secret_key}"
}
EOF
}

# -----------------------------------------------------------
# REMOTE STATE: Huawei Cloud OBS (S3-uyumlu)
# -----------------------------------------------------------
# Terraform state dosyasını yerel disk yerine bulut depolama
# alanında (OBS) saklar. Bu sayede:
# - Takım üyeleri aynı state'i paylaşabilir
# - State dosyası kaybolmaz / silinmez
# - Locking ile eş zamanlı değişiklikler önlenir
#
# path_relative_to_include() → her modül için benzersiz path üretir
# Örnek: dev/web-tier/terraform.tfstate
#
# ÖNCE YAPILMASI GEREKEN:
#   Huawei Cloud Console → OBS → Bucket Oluştur
#   Bucket adı: TG_STATE_BUCKET env değişkenindeki değer
#   Bölge: HW_REGION ile aynı olmalı

remote_state {
  backend = "s3"

  config = {
    bucket = local.state_bucket
    key    = "${path_relative_to_include()}/terraform.tfstate"
    region = local.region

    # OBS S3-uyumlu endpoint
    endpoint = "https://obs.${local.region}.myhuaweicloud.com"

    # OBS kimlik bilgileri (AK/SK)
    access_key = local.access_key
    secret_key = local.secret_key

    # Huawei Cloud OBS için gerekli S3 uyumluluk ayarları
    skip_credentials_validation = true
    skip_region_validation      = true
    skip_metadata_api_check     = true
    force_path_style            = true
  }

  # backend.tf dosyasını otomatik oluştur
  generate = {
    path      = "backend.tf"
    if_exists = "overwrite_terragrunt"
  }
}
