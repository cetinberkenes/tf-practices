terraform {
  required_providers {
    local  = { source = "hashicorp/local", version = ">= 2.4.0" }
    random = { source = "hashicorp/random", version = ">= 3.5.0" }
  }
}

# Rastgele bir UUID üret
resource "random_uuid" "proje_id" {}

# Üç farklı dosya oluştur — plan çıktısında 3 kaynak görürsünüz
resource "local_file" "config" {
  filename = "${path.module}/cikti/config.txt"
  content  = <<-EOT
    proje_id = ${random_uuid.proje_id.result}
    ortam    = production
    versiyon = 1.0.0
  EOT
}

resource "local_file" "readme" {
  filename = "${path.module}/cikti/README.txt"
  content  = "Bu dosya Terraform tarafından oluşturuldu.\n"
}

resource "local_file" "log" {
  filename = "${path.module}/cikti/deploy.log"
  content  = "Deploy tamamlandi: ${random_uuid.proje_id.result}\n"
}
