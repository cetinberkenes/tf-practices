terraform {
  required_providers {
    local  = { source = "hashicorp/local", version = ">= 2.4.0" }
    random = { source = "hashicorp/random", version = ">= 3.5.0" }
  }
}

# Bu bir modül — kendi başına çalıştırılmaz.
# Root main.tf içinden çağrılır.

resource "random_id" "sunucu_id" {
  byte_length = 4
}

resource "local_file" "sunucu_config" {
  filename = "${var.cikti_klasoru}/${var.sunucu_adi}.conf"
  content  = <<-EOT
    [server]
    name        = ${var.sunucu_adi}
    environment = ${var.ortam}
    port        = ${var.port}
    id          = ${random_id.sunucu_id.hex}
    region      = ${var.region}
  EOT
}
