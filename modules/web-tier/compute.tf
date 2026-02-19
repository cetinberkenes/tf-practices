# ===========================================================
# ADIM 4: ECS Instances (Elastic Cloud Server)
# ===========================================================
# count = var.ecs_count kullanarak aynı konfigürasyondan
# birden fazla sunucu oluşturulur.
#
# count.index: 0, 1, 2... şeklinde döner
# Örnek: count=2 ise workshop-ecs-1 ve workshop-ecs-2 oluşur
#
# Availability Zone dağılımı: sunucular farklı AZ'lara yayılır
# (HA — High Availability için iyi pratik)

resource "huaweicloud_compute_instance" "web" {
  count = var.ecs_count

  name              = "${var.prefix}-ecs-${count.index + 1}"
  image_id          = data.huaweicloud_images_image.ubuntu.id
  flavor_id         = local.flavor_id
  admin_pass        = var.ecs_password
  availability_zone = local.az_list[count.index % length(local.az_list)]

  # ECS hangi security group'a dahil olacak
  security_group_ids = [huaweicloud_networking_secgroup.ecs.id]

  # Hangi subnet'te çalışacak
  network {
    uuid = huaweicloud_vpc_subnet.main.id
  }

  # -----------------------------------------------------------
  # user_data: Sunucu ilk açıldığında çalışan cloud-init scripti
  # - nginx yükler
  # - Her sunucu kendi adını gösteren bir HTML sayfası oluşturur
  #   Bu sayede load balancer'ın hangi sunucuya gittiğini görebilirsiniz
  # -----------------------------------------------------------
  user_data = base64encode(<<-SCRIPT
    #!/bin/bash
    set -e

    # Paket listelerini güncelle ve nginx kur
    apt-get update -y
    apt-get install -y nginx

    # Her sunucuya özgü HTML sayfası oluştur
    cat > /var/www/html/index.html <<'HTML'
    <!DOCTYPE html>
    <html lang="tr">
    <head>
      <meta charset="UTF-8">
      <title>Terraform Workshop</title>
      <style>
        body { font-family: Arial, sans-serif; text-align: center; padding: 60px; background: #f0f4f8; }
        .card { background: white; border-radius: 12px; padding: 40px; display: inline-block;
                box-shadow: 0 4px 20px rgba(0,0,0,0.1); max-width: 500px; }
        h1 { color: #c7000b; }
        .badge { background: #c7000b; color: white; border-radius: 20px; padding: 6px 20px; }
      </style>
    </head>
    <body>
      <div class="card">
        <h1>Huawei Cloud + Terraform</h1>
        <h2>Yuk Dengeleme Calisiyor!</h2>
        <p>Bu istek sunucuya ulasti:</p>
        <p><span class="badge">HOSTNAME_PLACEHOLDER</span></p>
        <hr><small>Sayfayi yenileyerek farkli sunuculara gittigini gorun!</small>
      </div>
    </body>
    </html>
    HTML

    # Hostname'i HTML'e yerleştir
    HOSTNAME=$(hostname)
    sed -i "s/HOSTNAME_PLACEHOLDER/$HOSTNAME/g" /var/www/html/index.html

    # nginx servisini başlat ve otomatik açılışa ekle
    systemctl restart nginx
    systemctl enable nginx
  SCRIPT
  )

  tags = {
    Environment = "workshop"
    ManagedBy   = "terraform"
    Index       = tostring(count.index + 1)
    time        = local.time_tag
  }
}
