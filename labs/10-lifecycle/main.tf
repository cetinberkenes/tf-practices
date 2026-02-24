terraform {
  required_providers {
    random = { source = "hashicorp/random", version = ">= 3.5.0" }
    local  = { source = "hashicorp/local", version = ">= 2.4.0" }
  }
}

variable "etiket" {
  type    = string
  default = "v1"
}

# ════════════════════════════════════════════════════════════════════════════
# create_before_destroy
# ════════════════════════════════════════════════════════════════════════════
# Varsayılan davranış: önce eski sil, sonra yeni oluştur (kısa süre kesinti olur)
# create_before_destroy: önce yeni oluştur, sonra eskiyi sil (sıfır kesinti)

resource "random_string" "token" {
  length  = 16
  special = false

  lifecycle {
    create_before_destroy = true
  }
}

# ════════════════════════════════════════════════════════════════════════════
# ignore_changes
# ════════════════════════════════════════════════════════════════════════════
# Belirli alanlar dışarıda değiştirilse bile Terraform müdahale etmez.
# Örnek: Konsoldan elle değiştirilen tag'ler Terraform'u tetiklemesin.

resource "local_file" "log" {
  filename = "${path.module}/cikti/app.log"
  content  = "token=${random_string.token.result} etiket=${var.etiket}\n"

  lifecycle {
    # content değişirse Terraform bu dosyayı yeniden oluşturmaz
    ignore_changes = [content]
  }
}

# ════════════════════════════════════════════════════════════════════════════
# prevent_destroy
# ════════════════════════════════════════════════════════════════════════════
# Bu kaynak terraform destroy ile SİLİNEMEZ.
# Üretim veritabanları, kritik IP'ler için kullanılır.

resource "local_file" "kritik" {
  filename = "${path.module}/cikti/kritik.dat"
  content  = "Bu dosya SILINEMEZ (prevent_destroy)\n"

  lifecycle {
    prevent_destroy = true
  }
}

# TEST: Bu bloku yorum satırından çıkarın ve terraform destroy deneyin:
# → Error: Instance cannot be destroyed (prevent_destroy is set)

# ════════════════════════════════════════════════════════════════════════════
# replace_triggered_by (Terraform >= 1.2)
# ════════════════════════════════════════════════════════════════════════════
# Başka bir kaynak değiştiğinde bu kaynağı yeniden oluştur.

resource "random_string" "yenile_tetikleyici" {
  length  = 4
  special = false
  keepers = { etiket = var.etiket }
}

resource "local_file" "tetiklenen" {
  filename = "${path.module}/cikti/tetiklenen.txt"
  content  = "Bu dosya token değişince yenilenir: ${var.etiket}\n"

  lifecycle {
    replace_triggered_by = [random_string.yenile_tetikleyici]
  }
}

# DENEYIN:
#   terraform apply                   # İlk oluşturma
#   terraform apply -var="etiket=v2"  # token değişir → tetiklenen.txt yenilenir
