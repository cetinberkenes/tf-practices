terraform {
  required_providers {
    local  = { source = "hashicorp/local", version = ">= 2.4.0" }
    random = { source = "hashicorp/random", version = ">= 3.5.0" }
  }
}

# ─── Modül çağrısı ────────────────────────────────────────────────────────────
# source → modülün konumu (klasör, Git URL veya Terraform Registry)
# Her çağrı bağımsız bir kaynak seti oluşturur.

module "web_sunucu" {
  source = "./modules/server"

  sunucu_adi    = "web-01"
  ortam         = "dev"
  port          = 80
  cikti_klasoru = "${path.module}/cikti"
}

module "api_sunucu" {
  source = "./modules/server"

  sunucu_adi    = "api-01"
  ortam         = "dev"
  port          = 8080
  cikti_klasoru = "${path.module}/cikti"
}

module "prod_sunucu" {
  source = "./modules/server"

  sunucu_adi    = "web-prod"
  ortam         = "prod"
  port          = 443
  region        = "eu-west-101"
  cikti_klasoru = "${path.module}/cikti"
}

# ─── Modül output'larına erişim ───────────────────────────────────────────────
# Sözdizimi: module.<modul_adi>.<output_adi>

output "web_id" {
  value = module.web_sunucu.sunucu_id
}

output "api_id" {
  value = module.api_sunucu.sunucu_id
}

output "tum_sunucular" {
  value = {
    web  = module.web_sunucu.sunucu_id
    api  = module.api_sunucu.sunucu_id
    prod = module.prod_sunucu.sunucu_id
  }
}

# apply sonrası deneyin:
#   terraform state list
#   → module.web_sunucu.local_file.sunucu_config gibi modül içi kaynaklar görünür
#
#   terraform state show module.api_sunucu.random_id.sunucu_id
