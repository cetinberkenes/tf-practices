# ===========================================================
# ADIM 1: VPC (Virtual Private Cloud)
# ===========================================================
# VPC, buluttaki izole ağ ortamınızdır.
# Tüm kaynaklar bu VPC içinde çalışır.

resource "huaweicloud_vpc" "main" {
  name = "${var.prefix}-vpc"
  cidr = var.vpc_cidr

  tags = {
    Environment = "workshop"
    ManagedBy   = "terraform"
  }
}

# ===========================================================
# ADIM 2: Subnet
# ===========================================================
# VPC içinde alt ağ tanımlanır. ECS ve ELB bu subnet'te çalışır.

resource "huaweicloud_vpc_subnet" "main" {
  name       = "${var.prefix}-subnet"
  cidr       = var.subnet_cidr
  gateway_ip = cidrhost(var.subnet_cidr, 1) # İlk IP = gateway (örn: 10.0.1.1)
  vpc_id     = huaweicloud_vpc.main.id

  # DNS sunucuları — Huawei Cloud iç DNS
  dns_list = ["100.125.4.25", "8.8.8.8"]

  tags = {
    Environment = "workshop"
    ManagedBy   = "terraform"
  }
}

# ===========================================================
# ADIM 3: Security Groups
# ===========================================================
# Security Group = bulut güvenlik duvarı kuralları
#
# Mimari:
#   İnternet → ELB (port 80 açık) → ECS (sadece VPC içi port 80)
#                                   ECS (port 22 açık — SSH için)
#
# Bu sayede ECS'ler direkt internete açık olmaz, sadece ELB üzerinden erişilir.

# --- ELB Security Group ---
resource "huaweicloud_networking_secgroup" "elb" {
  name        = "${var.prefix}-sg-elb"
  description = "ELB icin guvenlik grubu — internet'ten HTTP izni"
}

# İnternetten ELB'ye port 80 (HTTP) erişimi
resource "huaweicloud_networking_secgroup_rule" "elb_http_ingress" {
  direction         = "ingress"
  ethertype         = "IPv4"
  protocol          = "tcp"
  port_range_min    = 80
  port_range_max    = 80
  remote_ip_prefix  = "0.0.0.0/0"
  security_group_id = huaweicloud_networking_secgroup.elb.id
  description       = "Internet'ten HTTP erisimi"
}

# --- ECS Security Group ---
resource "huaweicloud_networking_secgroup" "ecs" {
  name        = "${var.prefix}-sg-ecs"
  description = "ECS icin guvenlik grubu — VPC'den HTTP, her yerden SSH"
}

# SSH: Herhangi bir IP'den ECS'e bağlanabilmek için
# UYARI: Production ortamında bunu belirli IP ile kısıtlayın!
resource "huaweicloud_networking_secgroup_rule" "ecs_ssh_ingress" {
  direction         = "ingress"
  ethertype         = "IPv4"
  protocol          = "tcp"
  port_range_min    = 22
  port_range_max    = 22
  remote_ip_prefix  = "0.0.0.0/0"
  security_group_id = huaweicloud_networking_secgroup.ecs.id
  description       = "SSH erisimi (workshop icin acik, prod'da kisitlayin)"
}

# HTTP: Sadece VPC içinden (yani ELB'den) ECS'e port 80 erişimi
resource "huaweicloud_networking_secgroup_rule" "ecs_http_ingress" {
  direction         = "ingress"
  ethertype         = "IPv4"
  protocol          = "tcp"
  port_range_min    = 80
  port_range_max    = 80
  remote_ip_prefix  = var.vpc_cidr
  security_group_id = huaweicloud_networking_secgroup.ecs.id
  description       = "Sadece VPC icerisinden HTTP erisimi (ELB → ECS)"
}
