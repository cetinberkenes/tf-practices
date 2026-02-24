terraform {
  required_providers {
    local = { source = "hashicorp/local", version = ">= 2.4.0" }
  }
}

# ════════════════════════════════════════════════════════════════════════════
# BÖLÜM A: count
# ════════════════════════════════════════════════════════════════════════════
# count → sayıya göre aynı kaynaktan birden fazla oluştur
# Kaynak adları: local_file.count_dosya[0], local_file.count_dosya[1] ...

variable "dosya_sayisi" {
  type    = number
  default = 3
}

resource "local_file" "count_dosya" {
  count    = var.dosya_sayisi
  filename = "${path.module}/cikti/count/dosya-${count.index + 1}.txt"
  content  = "Ben ${count.index + 1}. dosyayim (count ile olusturuldum)\n"
}

# count ile oluşturulan kaynaklar bir LİSTE döndürür
output "count_dosya_yollari" {
  value = local_file.count_dosya[*].filename
}


# ════════════════════════════════════════════════════════════════════════════
# BÖLÜM B: for_each — map ile
# ════════════════════════════════════════════════════════════════════════════
# for_each → her key-value çifti için bir kaynak oluştur
# Kaynak adları: local_file.foreach_dosya["web"], local_file.foreach_dosya["db"] ...

variable "servisler" {
  type = map(object({
    port    = number
    tip     = string
  }))
  default = {
    web = { port = 80,   tip = "frontend" }
    api = { port = 8080, tip = "backend"  }
    db  = { port = 5432, tip = "database" }
  }
}

resource "local_file" "foreach_dosya" {
  for_each = var.servisler

  filename = "${path.module}/cikti/foreach/${each.key}.conf"
  content  = <<-EOT
    servis = ${each.key}
    port   = ${each.value.port}
    tip    = ${each.value.tip}
  EOT
}

# for_each ile oluşturulan kaynaklar bir MAP döndürür
output "foreach_dosya_yollari" {
  value = { for k, v in local_file.foreach_dosya : k => v.filename }
}


# ════════════════════════════════════════════════════════════════════════════
# BÖLÜM C: for_each — set ile
# ════════════════════════════════════════════════════════════════════════════
# toset() ile bir listeden set oluşturun

variable "ortamlar" {
  type    = list(string)
  default = ["dev", "staging", "prod"]
}

resource "local_file" "ortam_dosya" {
  for_each = toset(var.ortamlar)

  filename = "${path.module}/cikti/ortamlar/${each.key}.env"
  content  = "ENVIRONMENT=${each.key}\n"
}


# ════════════════════════════════════════════════════════════════════════════
# count vs for_each karşılaştırma notu:
#
#  count kullanın  → sayı yeterliyse ve kaynaklar birbirinin aynısıysa
#  for_each kullanın → her kaynağın farklı özelliği varsa (önerilen)
#
#  count dezavantajı: ortadaki eleman silinirse index'ler kayar,
#  Terraform geri kalan her şeyi yeniden oluşturmak ister!
#
#  Örnek sorun (count ile):
#    ["dev", "staging", "prod"]  →  [0]=dev [1]=staging [2]=prod
#    "staging" silinirse          →  [0]=dev [1]=prod
#    Terraform [1]=staging'i DESTROY edip [1]=prod OLUŞTURUR
#
#  for_each'te bu sorun yok — key'ler sabit kalır.
# ════════════════════════════════════════════════════════════════════════════
