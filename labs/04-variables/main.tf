terraform {
  required_providers {
    local = { source = "hashicorp/local", version = ">= 2.4.0" }
  }
}

# Değişkenleri kullanan kaynaklar

resource "local_file" "app_config" {
  filename = "${path.module}/cikti/app.conf"
  content  = <<-EOT
    app_name    = ${var.app_name}
    environment = ${var.environment}
    port        = ${var.port}
    debug       = ${var.debug_mode}
    region      = ${var.region}
  EOT
}

resource "local_file" "env_file" {
  filename = "${path.module}/cikti/.env"

  # sensitive değişkeni değeri gizli tutulur ama dosyaya yazılabilir
  content = <<-EOT
    APP_NAME=${var.app_name}
    APP_PORT=${var.port}
    DB_PASSWORD=${var.db_password}
    ENVIRONMENT=${var.environment}
  EOT
}
