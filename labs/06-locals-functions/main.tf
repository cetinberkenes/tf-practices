terraform {
  required_providers {
    local = { source = "hashicorp/local", version = ">= 2.4.0" }
  }
}

variable "ortam" {
  type    = string
  default = "dev"
}

variable "proje" {
  type    = string
  default = "workshop"
}

variable "ekstra_etiketler" {
  type    = map(string)
  default = { Sahip = "DevTeam" }
}

# ─── locals bloğu ─────────────────────────────────────────────────────────────
# locals, tekrarlayan değerleri bir kez tanımlamak için kullanılır.
# değişken değil — dışarıdan değiştirilemez.

locals {
  # String fonksiyonları
  proje_buyuk = upper(var.proje)                                  # "WORKSHOP"
  etiket_adi  = format("%s-%s", var.proje, var.ortam)             # "workshop-dev"
  temiz_ad    = replace(local.etiket_adi, "-", "_")               # "workshop_dev"

  # Map fonksiyonları
  ortak_etiketler = merge(
    var.ekstra_etiketler,
    {
      Environment = var.ortam
      ManagedBy   = "terraform"
      Proje       = var.proje
    }
  )

  # Liste fonksiyonları
  sunucular  = ["web-1", "web-2", "db-1"]
  etiket_set = toset(local.sunucular)         # listeyi set'e çevir (tekrar yok)
  ilk_sunucu = element(local.sunucular, 0)    # "web-1"
  sunucu_say = length(local.sunucular)        # 3

  # Koşullu ifade (ternary)
  log_seviye = var.ortam == "prod" ? "ERROR" : "DEBUG"

  # cidrsubnet ile subnet hesaplama
  vpc_cidr     = "10.0.0.0/16"
  subnet_1     = cidrsubnet(local.vpc_cidr, 8, 0)  # "10.0.0.0/24"
  subnet_2     = cidrsubnet(local.vpc_cidr, 8, 1)  # "10.0.1.0/24"
}

# Locals değerlerini bir dosyaya yaz — sonuçları görmek için
resource "local_file" "rapor" {
  filename = "${path.module}/cikti/locals_raporu.txt"
  content  = <<-EOT
    proje_buyuk  : ${local.proje_buyuk}
    etiket_adi   : ${local.etiket_adi}
    temiz_ad     : ${local.temiz_ad}
    log_seviye   : ${local.log_seviye}
    sunucu_sayisi: ${local.sunucu_say}
    ilk_sunucu   : ${local.ilk_sunucu}
    subnet_1     : ${local.subnet_1}
    subnet_2     : ${local.subnet_2}

    Etiketler:
    %{for k, v in local.ortak_etiketler}  ${k} = ${v}
    %{endfor}
  EOT
}
