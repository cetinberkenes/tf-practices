# -----------------------------------------------------------
# NOT: region, access_key, secret_key değişkenleri burada yok.
# Bu bilgiler Terragrunt root konfigürasyonundan sağlanır
# ve provider.tf dosyasına otomatik olarak yazılır.
# -----------------------------------------------------------

variable "prefix" {
  description = "Tüm kaynaklara eklenecek isim öneki"
  type        = string
  default     = "workshop"
}

variable "vpc_cidr" {
  description = "VPC için CIDR bloğu"
  type        = string
  default     = "10.0.0.0/16"
}

variable "subnet_cidr" {
  description = "Subnet için CIDR bloğu"
  type        = string
  default     = "10.0.1.0/24"
}

variable "ecs_count" {
  description = "Kaç adet ECS instance oluşturulacak (en az 2 önerilir)"
  type        = number
  default     = 2

  validation {
    condition     = var.ecs_count >= 1 && var.ecs_count <= 5
    error_message = "ECS sayısı 1 ile 5 arasında olmalıdır."
  }
}

variable "ecs_password" {
  description = "ECS instance root şifresi (en az 8 karakter, büyük/küçük harf + rakam içermeli)"
  type        = string
  sensitive   = true
}

variable "ecs_flavor" {
  description = "ECS instance tipi. Boş bırakılırsa otomatik seçilir."
  type        = string
  default     = ""
}

variable "bandwidth_size" {
  description = "ELB EIP bant genişliği (Mbit/s)"
  type        = number
  default     = 5
}
