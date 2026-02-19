# ===========================================================
# ADIM 5: EIP (Elastic IP — Sabit Public IP)
# ===========================================================
# EIP, ELB'ye atanacak public IP adresidir.
# Kullanıcılar web sitesine bu IP üzerinden erişir.
# Önce EIP oluşturulur, sonra ELB'ye bağlanır.

resource "huaweicloud_vpc_eip" "elb" {
  publicip {
    type = "5_bgp" # BGP (Border Gateway Protocol) — çok yönlü ağ
  }

  bandwidth {
    name        = "${var.prefix}-elb-bw"
    size        = var.bandwidth_size
    share_type  = "PER"     # Dedicated bandwidth (paylaşımsız)
    charge_mode = "traffic" # Trafik bazlı ücretlendirme
  }

  tags = {
    Environment = "workshop"
    ManagedBy   = "terraform"
  }
}

# ===========================================================
# ADIM 6: ELB — Dedicated Load Balancer
# ===========================================================
# Dedicated ELB: Huawei Cloud'un yeni nesil yük dengeleyicisi.
# Kaynak türü: huaweicloud_elb_loadbalancer
#
# ipv4_subnet_id: ELB'nin iç IP'sinin oluşturulacağı subnet
# ipv4_eip_id   : ELB'ye bağlanacak public EIP

resource "huaweicloud_elb_loadbalancer" "main" {
  name        = "${var.prefix}-elb"
  description = "Workshop yuk dengeleyici"

  # VPC ve subnet bilgileri
  vpc_id         = huaweicloud_vpc.main.id
  ipv4_subnet_id = huaweicloud_vpc_subnet.main.subnet_id

  # ELB'nin çalışacağı Availability Zone(lar)
  availability_zone = [local.az_list[0]]

  # EIP'yi ELB'ye doğrudan bağla
  ipv4_eip_id = huaweicloud_vpc_eip.elb.id

  tags = {
    Environment = "workshop"
    ManagedBy   = "terraform"
  }
}

# ===========================================================
# ADIM 7: Backend Pool (Arka uç sunucu grubu)
# ===========================================================
# Pool, hangi sunucuların trafik alacağını tanımlar.
#
# lb_method seçenekleri:
#   ROUND_ROBIN      — Sırayla dağıt (default, workshop için ideal)
#   LEAST_CONNECTIONS — En az bağlantı olan sunucuya gönder
#   SOURCE_IP         — Aynı IP her zaman aynı sunucuya gitsin

resource "huaweicloud_elb_pool" "http" {
  name            = "${var.prefix}-pool"
  protocol        = "HTTP"
  lb_method       = "ROUND_ROBIN"
  loadbalancer_id = huaweicloud_elb_loadbalancer.main.id
  description     = "HTTP backend pool"
}

# ===========================================================
# ADIM 8: Health Monitor (Sağlık kontrolü)
# ===========================================================
# ELB düzenli aralıklarla sunucuları kontrol eder.
# Yanıt vermeyen sunucu otomatik olarak pool'dan çıkarılır.
#
# interval   : Kaç saniyede bir kontrol yapılsın?
# timeout    : Yanıt için kaç saniye beklensin?
# max_retries: Kaç başarısız denemeden sonra sunucu "down" sayılsın?

resource "huaweicloud_elb_monitor" "http" {
  pool_id      = huaweicloud_elb_pool.http.id
  protocol     = "HTTP"
  interval     = 5
  timeout      = 3
  max_retries  = 3
  url_path     = "/"    # Kontrol edilecek URL path (HTTP 200 beklenir)
  monitor_port = 80
}

# ===========================================================
# ADIM 9: Listener (Dinleyici)
# ===========================================================
# Listener, ELB'nin hangi protokol ve port'u dinleyeceğini tanımlar.
# Gelen istekler default_pool_id'deki sunuculara yönlendirilir.

resource "huaweicloud_elb_listener" "http" {
  name            = "${var.prefix}-listener-http"
  description     = "HTTP 80 portu dinleyicisi"
  protocol        = "HTTP"
  protocol_port   = 80
  loadbalancer_id = huaweicloud_elb_loadbalancer.main.id
  default_pool_id = huaweicloud_elb_pool.http.id
}

# ===========================================================
# ADIM 10: Pool Members (Arka uç sunucular)
# ===========================================================
# Her ECS instance, backend pool'a member olarak eklenir.
# count.index ile ECS listesini tek tek dolaşır.
#
# address      : ECS'nin VPC içi (private) IP adresi
# protocol_port: ECS'de nginx'in dinlediği port (80)
# subnet_id    : Üyelerin bulunduğu subnet

resource "huaweicloud_elb_member" "web" {
  count = var.ecs_count

  pool_id       = huaweicloud_elb_pool.http.id
  address       = huaweicloud_compute_instance.web[count.index].access_ip_v4
  protocol_port = 80
  subnet_id     = huaweicloud_vpc_subnet.main.subnet_id

  # ELB, member'ların sağlıklı olduğunu monitor ile doğrular
  depends_on = [huaweicloud_elb_monitor.http]
}
