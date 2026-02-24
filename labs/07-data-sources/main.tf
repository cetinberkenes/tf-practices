terraform {
  required_providers {
    local = { source = "hashicorp/local", version = ">= 2.4.0" }
  }
}

# ─── resource vs data farkı ───────────────────────────────────────────────────
#
#  resource → Terraform bir şey OLUŞTURUR ve yönetir
#  data     → Terraform mevcut bir şeyi OKUR, değiştirmez
#
# Örnek:
#   resource "local_file" "yeni"  → yeni dosya oluştur
#   data "local_file" "mevcut"    → var olan dosyayı oku

# LAB ADIM 1: Önce bir dosya oluşturun (data source bunu okuyacak)
resource "local_file" "kaynak_dosya" {
  filename = "${path.module}/cikti/kaynak.json"
  content  = jsonencode({
    app     = "workshop"
    version = "2.0.0"
    ortam   = "dev"
  })
}

# LAB ADIM 2: Oluşturulan dosyayı data source ile oku
# NOT: depends_on ile oluşturulma sırasını garantileyin
data "local_file" "okunan_dosya" {
  filename   = local_file.kaynak_dosya.filename
  depends_on = [local_file.kaynak_dosya]
}

# LAB ADIM 3: Okunan içeriği başka bir kaynakta kullan
resource "local_file" "islenmus" {
  filename = "${path.module}/cikti/islenmis.txt"
  content  = <<-EOT
    Orijinal dosya okundu.
    Icerik uzunlugu: ${length(data.local_file.okunan_dosya.content)} karakter
    Icerik:
    ${data.local_file.okunan_dosya.content}
  EOT
}

output "dosya_icerik" {
  value = jsondecode(data.local_file.okunan_dosya.content)
}
