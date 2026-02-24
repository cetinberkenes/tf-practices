output "sunucu_id" {
  description = "Sunucunun benzersiz ID'si"
  value       = random_id.sunucu_id.hex
}

output "config_dosyasi" {
  description = "Oluşturulan config dosyası yolu"
  value       = local_file.sunucu_config.filename
}
