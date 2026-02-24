terraform {
  required_version = ">= 1.3.0"

  required_providers {
    # "local" provider — bilgisayarda dosya oluşturur.
    # Bulut hesabı gerekmez, öğrenmek için idealdir.
    local = {
      source  = "hashicorp/local"
      version = ">= 2.4.0"
    }

    # "random" provider — rastgele değer üretir.
    random = {
      source  = "hashicorp/random"
      version = ">= 3.5.0"
    }
  }
}

# ─── İlk kaynak: rastgele bir string üret ─────────────────────────────────────
resource "random_string" "isim" {
  length  = 8
  upper   = false
  special = false
}

# ─── İkinci kaynak: bilgisayarda bir dosya oluştur ────────────────────────────
resource "local_file" "merhaba" {
  filename = "${path.module}/cikti/merhaba.txt"
  content  = "Merhaba Terraform! ID: ${random_string.isim.result}\n"
}
