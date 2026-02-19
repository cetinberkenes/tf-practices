# ===========================================================
# OUTPUTS — terraform apply sonrası gösterilecek bilgiler
# ===========================================================
# Outputs, altyapı kurulduktan sonra önemli bilgileri
# terminale yazdırır. Diğer Terraform modülleri tarafından
# da kullanılabilir.

output "web_url" {
  description = "Web sitesine erişim URL'i (ELB public IP)"
  value       = "http://${huaweicloud_vpc_eip.elb.address}"
}

output "elb_public_ip" {
  description = "ELB'nin public IP adresi"
  value       = huaweicloud_vpc_eip.elb.address
}

output "ecs_private_ips" {
  description = "ECS instance'larının VPC içi (private) IP adresleri"
  value       = [for instance in huaweicloud_compute_instance.web : instance.access_ip_v4]
}

output "ecs_names" {
  description = "Oluşturulan ECS instance isimleri"
  value       = [for instance in huaweicloud_compute_instance.web : instance.name]
}

output "vpc_id" {
  description = "Oluşturulan VPC'nin ID'si"
  value       = huaweicloud_vpc.main.id
}

output "subnet_id" {
  description = "Oluşturulan Subnet'in ID'si"
  value       = huaweicloud_vpc_subnet.main.id
}

output "elb_id" {
  description = "ELB'nin ID'si"
  value       = huaweicloud_elb_loadbalancer.main.id
}

output "workshop_summary" {
  description = "Workshop altyapısına genel bakış"
  value = <<-SUMMARY
    ============================================================
    WORKSHOP ALTYAPISI HAZIR!
    ============================================================
    Web Sitesi  : http://${huaweicloud_vpc_eip.elb.address}
    ECS Sayisi  : ${var.ecs_count}
    ECS Sunucular: ${join(", ", [for i in huaweicloud_compute_instance.web : i.name])}
    VPC CIDR    : ${var.vpc_cidr}
    Bolge       : ${var.region}

    TEST:
    curl http://${huaweicloud_vpc_eip.elb.address}
    Sayfayi birden fazla yenile — farkli sunuculara gittiginizi gorun!
    ============================================================
  SUMMARY
}
