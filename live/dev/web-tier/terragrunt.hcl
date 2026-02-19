# ===========================================================
# DEV ORTAMI — Web Tier Modülü
# ===========================================================
# Bu dosya, web-tier modülünü dev ortamı için çalıştırır.
# Root terragrunt.hcl'den provider ve remote state miras alır.
#
# Yapı:
#   live/
#   ├── terragrunt.hcl          ← Root (provider + remote state)
#   └── dev/
#       └── web-tier/
#           └── terragrunt.hcl  ← Bu dosya
# ===========================================================

# Root konfigürasyonunu miras al
# find_in_parent_folders() → üst klasörlerde terragrunt.hcl arar
include "root" {
  path = find_in_parent_folders()
}

# -----------------------------------------------------------
# Hangi Terraform modülü kullanılacak?
# -----------------------------------------------------------
# get_repo_root() → git reposunun kök dizinini döndürür
# Bu sayede path'ler her ortamdan doğru çalışır.

terraform {
  source = "${get_repo_root()}/modules/web-tier"
}

# -----------------------------------------------------------
# Modüle geçirilecek input değişkenleri
# -----------------------------------------------------------
# Bu inputs, terraform.tfvars yerine geçer.
# Her ortam (dev/staging/prod) farklı inputs kullanabilir.
#
# Örnek farklılıklar:
#   dev:     ecs_count=2, bandwidth=5
#   staging: ecs_count=3, bandwidth=10
#   prod:    ecs_count=4, bandwidth=50

inputs = {
  # Kaynak isim öneki — tüm kaynaklar "dev-workshop-" ile başlar
  prefix = "dev-workshop"

  # Ağ konfigürasyonu
  vpc_cidr    = "10.0.0.0/16"
  subnet_cidr = "10.0.1.0/24"

  # ECS konfigürasyonu
  ecs_count = 2

  # ECS şifresi çevre değişkeninden okunur — kod içine yazmayın!
  # export TF_VAR_ecs_password="Sifreniz@123"
  ecs_password = get_env("TF_VAR_ecs_password", "")

  # ECS flavor (boş = otomatik seçim)
  ecs_flavor = ""

  # ELB bant genişliği (Mbit/s)
  bandwidth_size = 5
}
