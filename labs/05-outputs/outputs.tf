# ─── Temel output ─────────────────────────────────────────────────────────────
output "sunucu_adi" {
  description = "Oluşturulan sunucu adı"
  value       = random_pet.sunucu.id
}

output "port" {
  description = "Uygulama portu"
  value       = random_integer.port.result
}

output "baglanti_adresi" {
  description = "Sunucuya bağlantı adresi"
  value       = "http://${random_pet.sunucu.id}:${random_integer.port.result}"
}

# ─── sensitive output — terminalde (sensitive) görünür ────────────────────────
output "api_key" {
  description = "API anahtarı (sensitive)"
  value       = random_string.api_key.result
  sensitive   = true
}

# ─── Nesne (object) output ────────────────────────────────────────────────────
output "sunucu_bilgileri" {
  description = "Sunucu bilgileri özeti"
  value = {
    ad   = random_pet.sunucu.id
    port = random_integer.port.result
    url  = "http://${random_pet.sunucu.id}:${random_integer.port.result}"
  }
}

# apply sonrası deneyin:
#   terraform output                      → tüm outputlar
#   terraform output sunucu_adi           → tek output
#   terraform output -json                → JSON formatında
#   terraform output -raw sunucu_adi      → düz metin (script'lerde kullanışlı)
#   terraform output api_key              → sensitive bile olsa gösterir
