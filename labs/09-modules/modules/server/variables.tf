variable "sunucu_adi" {
  description = "Sunucu adı"
  type        = string
}

variable "ortam" {
  description = "Ortam (dev/staging/prod)"
  type        = string
  default     = "dev"
}

variable "port" {
  description = "Uygulama portu"
  type        = number
  default     = 8080
}

variable "region" {
  description = "Bölge"
  type        = string
  default     = "tr-west-1"
}

variable "cikti_klasoru" {
  description = "Config dosyasının yazılacağı klasör"
  type        = string
}
