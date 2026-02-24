# ─── Tip: string ──────────────────────────────────────────────────────────────
variable "app_name" {
  description = "Uygulama adı"
  type        = string
  default     = "benim-appim"
}

# ─── Tip: string — validation ile ────────────────────────────────────────────
variable "environment" {
  description = "Ortam adı"
  type        = string
  default     = "dev"

  validation {
    condition     = contains(["dev", "staging", "prod"], var.environment)
    error_message = "Ortam 'dev', 'staging' veya 'prod' olmalıdır."
  }
}

# ─── Tip: number ──────────────────────────────────────────────────────────────
variable "port" {
  description = "Uygulama portu"
  type        = number
  default     = 8080

  validation {
    condition     = var.port >= 1024 && var.port <= 65535
    error_message = "Port 1024-65535 arasında olmalıdır."
  }
}

# ─── Tip: bool ────────────────────────────────────────────────────────────────
variable "debug_mode" {
  description = "Debug modu açık mı?"
  type        = bool
  default     = false
}

# ─── Tip: string — sensitive ──────────────────────────────────────────────────
# sensitive = true → plan/apply çıktısında değer görünmez, (sensitive) yazar
variable "db_password" {
  description = "Veritabanı şifresi (terraform.tfvars ile sağlayın)"
  type        = string
  sensitive   = true
}

# ─── Tip: string — default yok, zorunlu ──────────────────────────────────────
variable "region" {
  description = "Bölge (zorunlu — default değer yok)"
  type        = string
}

# ─── DENEME: Bu satırı yorum satırından çıkarın, ne olduğunu görün ───────────
# variable "yanlis_ortam" {
#   type    = string
#   default = "test"
#   validation {
#     condition     = contains(["dev", "prod"], var.yanlis_ortam)
#     error_message = "Sadece dev veya prod olabilir."
#   }
# }
