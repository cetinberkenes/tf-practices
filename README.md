# Huawei Cloud + Terraform Workshop
## Ölçeklenebilir Web Katmanı (ELB + ECS)

**Süre:** ~60 dakika
**Seviye:** Başlangıç
**Kazanımlar:** Terraform'un temel kullanımı, load balancer mimarisi, bulut altyapısı yönetimi

---

## Terraform Nedir? (Hiç bilmiyorum diyenler için)

Terraform, bulut altyapısını **kod yazarak** yönetmenizi sağlayan bir araçtır.

Normalde bir sunucu oluşturmak için şunları yaparsınız:
1. Cloud konsoluna giriş yaparsınız
2. Fare ile tıklayarak ayarları doldurusunuz
3. "Oluştur" butonuna basarsınız

Terraform ile bunların hepsini bir `.tf` dosyasına yazarsınız ve tek komutla uygularsınız. Bu yaklaşımın avantajları:
- Aynı altyapıyı tekrar tekrar kurabilirsiniz (hata olmaz)
- Ne kurduğunuzu takip edebilirsiniz
- Tek komutla her şeyi silebilirsiniz

### Terraform'un 4 Temel Komutu

| Komut | Ne yapar? |
|-------|-----------|
| `terraform init` | Gerekli eklentileri indirir (bir kez yapılır) |
| `terraform plan` | "Neyi değiştireceğim?" diye gösterir, hiçbir şey yapmaz |
| `terraform apply` | Altyapıyı gerçekten oluşturur |
| `terraform destroy` | Oluşturulan her şeyi siler |

> **Not:** `plan` her zaman güvenlidir — hiçbir şey oluşturmaz, sadece önizler.

---

## Mimari

```
                        ┌─────────────────────────────────────┐
                        │           Huawei Cloud               │
  İnternet              │                                      │
  ─────────  Public IP  │  ┌──────────────────────────────┐   │
  Kullanıcı ──────────► │  │  ELB (Elastic Load Balancer) │   │
                        │  │  Security Group: sg-elb       │   │
                        │  │  Port 80 ◄── internet         │   │
                        │  └──────────┬───────────────────┘   │
                        │             │ ROUND_ROBIN            │
                        │       ┌─────┴──────┐                 │
                        │       ▼            ▼                 │
                        │  ┌─────────┐  ┌─────────┐           │
                        │  │ ECS-1   │  │ ECS-2   │           │
                        │  │ nginx   │  │ nginx   │           │
                        │  │ AZ-1    │  │ AZ-2    │           │
                        │  └─────────┘  └─────────┘           │
                        │     Security Group: sg-ecs           │
                        │     Port 80: sadece VPC içi          │
                        │     Port 22: SSH (internet)          │
                        │                                      │
                        │  VPC: 10.0.0.0/16                    │
                        │  Subnet: 10.0.1.0/24                 │
                        └─────────────────────────────────────┘
```

**Bu mimaride ne var?**
- **EIP:** Sabit public IP — kullanıcılar bu adrese bağlanır
- **ELB:** Gelen trafiği sunucular arasında dengeler
- **ECS-1, ECS-2:** Web sunucuları (nginx çalışır)
- **VPC/Subnet:** Sunucuların bulunduğu özel ağ

---

## Ön Gereksinimler

- [ ] [Terraform](https://developer.hashicorp.com/terraform/install) kurulu (>= 1.3.0)
- [ ] Huawei Cloud hesabı
- [ ] IAM Access Key (AK) ve Secret Key (SK)

### AK/SK Nasıl Alınır?
1. Huawei Cloud Console'a giriş yap
2. Sağ üst köşe → Kullanıcı adı → **Benim Kimlik Bilgilerim**
3. **Erişim Anahtarları** sekmesi → **Erişim Anahtarı Oluştur**
4. İndirilen CSV dosyasından AK ve SK'yı al

---

## Dosya Yapısı

```
tf-practices/
└── modules/
    └── web-tier/
        ├── main.tf                   # Terraform ayarları + Data sources
        ├── provider.tf               # Huawei Cloud provider
        ├── network.tf                # VPC, Subnet, Security Groups
        ├── compute.tf                # ECS instances (count kullanımı)
        ├── elb.tf                    # ELB, Listener, Pool, Members, EIP
        ├── variables.tf              # Değişken tanımları
        ├── outputs.tf                # Apply sonrası gösterilecek bilgiler
        └── terraform.tfvars.example  # Örnek değişken dosyası
```

---

## Workshop Adımları

### 1. Hazırlık (5 dk)

> **Önemli:** Tüm komutları `modules/web-tier/` klasöründen çalıştırın!

```bash
# Repoyu klonla
git clone <repo-url>

# DOĞRU klasöre gir — bu adımı atlamayın!
cd tf-practices/modules/web-tier
```

Nerede olduğunuzu doğrulayın:
```bash
ls
# Şunu görmelisiniz: main.tf  provider.tf  network.tf  compute.tf  elb.tf  ...
```

Eğer `.tf` dosyaları göremiyorsanız yanlış klasördesiniz demektir. `pwd` ile bulunduğunuz yeri kontrol edin.

```bash
# Örnek değişken dosyasını kopyala
cp terraform.tfvars.example terraform.tfvars
```

`terraform.tfvars` dosyasını bir metin editörüyle açın ve gerçek değerlerinizi girin:

```hcl
region       = "tr-west-1"
access_key   = "AK_BURAYA"
secret_key   = "SK_BURAYA"
ecs_password = "Sifreniz@2024!"
```

> **Güvenlik:** `terraform.tfvars` dosyasını asla git'e commit etmeyin — içinde şifreler var!

---

### 2. Terraform Init (3 dk)

```bash
terraform init
```

Bu komut Huawei Cloud provider eklentisini internetten indirir. İnternet bağlantısı gerektirir ve **sadece bir kez** yapılması yeterlidir.

**Beklenen çıktı:**
```
Initializing provider plugins...
- Installing huaweicloud/huaweicloud v1.60.x...
Terraform has been successfully initialized!
```

---

### 3. Kodu İncele (10 dk)

Dosyaları sırayla inceleyin ve açıklamaları okuyun:

**`main.tf`** — Provider ve Data Sources
- Provider nasıl tanımlanır?
- `data` kaynakları nedir? `resource`'dan farkı ne?
- `locals` bloğu ne işe yarar?

**`network.tf`** — Ağ Altyapısı
- VPC ve Subnet arasındaki ilişkiyi inceleyin
- `huaweicloud_networking_secgroup_rule` nasıl çalışıyor?
- ELB ve ECS için neden farklı security group kullandık?

**`compute.tf`** — ECS Instances
- `count` nasıl çalışıyor?
- `count.index` neyi temsil ediyor?
- `availability_zone = local.az_list[count.index % length(local.az_list)]` ne yapıyor?

**`elb.tf`** — Load Balancer
- EIP → ELB → Listener → Pool → Member zincirini takip edin
- `depends_on` neden kullanıldı?
- Health monitor olmadan ne olur?

---

### 4. Plan — Değişiklikleri Önizle (5 dk)

```bash
terraform plan
```

Terraform'un oluşturacağı kaynakları listeleyin:

| Kaynak | Sayı |
|--------|------|
| VPC | 1 |
| Subnet | 1 |
| Security Group | 2 |
| Security Group Rule | 3 |
| ECS Instance | 2 |
| EIP | 1 |
| ELB | 1 |
| ELB Listener | 1 |
| ELB Pool | 1 |
| ELB Monitor | 1 |
| ELB Member | 2 |
| **Toplam** | **~16** |

> `plan` komutu hiçbir şey oluşturmaz! Sadece önizleme yapar.

**Çıktıdaki sembollerin anlamı:**
- `+` — Bu kaynak oluşturulacak
- `~` — Bu kaynak değiştirilecek
- `-` — Bu kaynak silinecek

---

### 5. Apply — Altyapıyı Oluştur (15-20 dk)

```bash
terraform apply
```

Terraform önce `plan` çıktısını gösterir ve onay ister. `yes` yazıp Enter'a basın.

> Terraform'un kayıtları (state dosyası): Terraform hangi kaynakları oluşturduğunu `terraform.tfstate` dosyasında saklar. Bu dosyayı **silmeyin** — silirseniz Terraform ne oluşturduğunu unutur.

**Apply tamamlandığında:**
```
workshop_summary = <<EOT
============================================================
WORKSHOP ALTYAPISI HAZIR!
============================================================
Web Sitesi  : http://xxx.xxx.xxx.xxx
ECS Sayisi  : 2
ECS Sunucular: workshop-ecs-1, workshop-ecs-2
...
============================================================
EOT
```

---

### 6. Test Et (10 dk)

**Tarayıcı ile test:**
```
http://<elb_public_ip>
```
Sayfayı birkaç kez yenileyin — farklı sunucuların adını göreceksiniz!

**curl ile test:**
```bash
# 10 istek gönder, hangi sunuculara gittiğini gör
for i in $(seq 1 10); do
  curl -s http://<elb_public_ip> | grep "badge"
done
```

**SSH ile ECS'e bağlan:**
```bash
# ECS'lerin IP'lerini öğren
terraform output ecs_private_ips

# Not: ECS'lerin public IP'si yok, ELB üzerinden erişilir.
# Doğrudan SSH için ECS'e ayrıca EIP atanmalıdır.
```

---

### 7. Deneyler (5 dk)

**A. ECS sayısını artır:**
```hcl
# terraform.tfvars içinde
ecs_count = 3
```
```bash
terraform apply  # Yeni ECS ve member otomatik eklenir
```

**B. Bandwidth'i değiştir:**
```hcl
bandwidth_size = 10
```
```bash
terraform plan   # Sadece EIP bandwidth değişir
terraform apply
```

**C. State'i incele:**
```bash
terraform state list                                        # Tüm kaynakları listele
terraform state show huaweicloud_elb_loadbalancer.main     # ELB detayı
```

**D. Output'ları sorgula:**
```bash
terraform output web_url
terraform output ecs_private_ips
```

---

### 8. Temizlik — Destroy (5 dk)

> Workshop bitiminde tüm kaynakları silmek **ücret** oluşmaması için kritiktir!

```bash
terraform destroy
```

`yes` yazarak onaylayın. Terraform tüm oluşturduğu kaynakları siler.

**Doğrulama:**
```bash
# State boş olmalı
terraform state list  # Boş çıktı beklenir

# Huawei Cloud Console'dan da kontrol et
```

---

## Sık Karşılaşılan Hatalar ve Çözümleri

### "Error: error deleting listener: conflict in the request"

**Neden olur?**
Listener silinmeye çalışılırken, ona bağlı başka kaynaklar (pool member'lar gibi) henüz silinmemiştir. Huawei Cloud bu durumu "conflict" olarak raporlar.

**Çözüm 1 — Birkaç dakika bekleyip tekrar dene:**
```bash
terraform destroy
```
Bazen geçici bir sıralama problemidir. 1-2 dakika bekleyip aynı komutu tekrar çalıştırın.

**Çözüm 2 — State'i yenile ve tekrar dene:**
```bash
terraform refresh   # Cloud'daki gerçek durumu state ile senkronize eder
terraform destroy
```

**Çözüm 3 — Kaynağı state'den çıkar, manuel sil:**
```bash
# Terraform'un takibinden çıkar
terraform state rm huaweicloud_elb_listener.http

# Sonra destroy'u tamamla
terraform destroy
```
Kalan kaynakları Huawei Cloud Console'dan manuel olarak silebilirsiniz.

---

### "Warning: Resource not found — the resource is gone and will be removed in Terraform state"

**Bu bir hata değil, uyarıdır.**

Terraform şunu söylüyor: "Bu kaynaklar cloud'da artık yok (belki konsol üzerinden manuel silindi), state dosyasından temizleyeceğim."

**Ne yapmanız gerekiyor?**
Hiçbir şey. Sadece devam edin:
```bash
terraform destroy
# veya
terraform apply
```
Terraform bu kaynakları otomatik olarak state'den kaldırıp devam eder.

---

### "Error: No flavors found"

Bölgede uygun flavor bulunamadı. `ecs_flavor` değişkenini elle belirtin:
```hcl
# terraform.tfvars içinde
ecs_flavor = "s6.small.1"
```

---

### "Error: image not found"

Bölgede Ubuntu 22.04 farklı isimde olabilir. Konsol'dan Public Images'a bakın ve doğru ismi `main.tf` içindeki `data "huaweicloud_images_image"` bloğuna yazın.

---

### "Error 401: Unauthorized"

AK/SK yanlış veya bölge uyuşmuyor. `terraform.tfvars` dosyasını kontrol edin:
- `access_key` ve `secret_key` doğru mu?
- `region` değeri konsolda göründüğü gibi mi? (örn. `tr-west-1`)

---

### Web sitesi açılmıyor

- nginx başlaması 2-3 dakika alabilir, bekleyin
- Security Group kurallarını kontrol edin
- ELB health monitor durumuna bakın: Console → ELB → Backend Groups

---

### Yanlış klasörde "not a git repository" veya ".tf dosyaları bulunamıyor"

Terraform komutlarını mutlaka `modules/web-tier/` klasöründen çalıştırın:
```bash
# Nerede olduğunuzu kontrol edin
pwd

# Doğru klasöre gidin
cd tf-practices/modules/web-tier

# Klasörde .tf dosyaları olmalı
ls *.tf
```

---

## Öğrenilen Kavramlar

| Kavram | Nerede? |
|--------|---------|
| `terraform init/plan/apply/destroy` | Tüm süreç |
| `variable` & `validation` | `variables.tf` |
| `data` source | `main.tf` (AZ, image, flavor) |
| `locals` | `main.tf` |
| `count` meta-argument | `compute.tf`, `elb.tf` |
| `count.index` | `compute.tf` |
| `% (modulo)` ile AZ dağılımı | `compute.tf` |
| `depends_on` | `elb.tf` |
| Resource referansı | `elb.tf` → `compute.tf` |
| `for` expression | `outputs.tf` |
| `sensitive` variable | `variables.tf` |
| Security Group segmentasyonu | `network.tf` |
| `terraform state` komutları | Temizlik adımı |
| `terraform refresh` | Hata çözümü |

---

## Kaynaklar

- [Huawei Cloud Terraform Provider Docs](https://registry.terraform.io/providers/huaweicloud/huaweicloud/latest/docs)
- [Provider GitHub](https://github.com/huaweicloud/terraform-provider-huaweicloud)
- [Terraform Dili Referansı](https://developer.hashicorp.com/terraform/language)
