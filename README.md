# Huawei Cloud + Terraform Workshop
## Fikir 3: Ölçeklenebilir Web Katmanı (ELB + ECS)

> **NOT — Yapı Güncellendi!**
> Bu repo artık **Terragrunt** kullanacak şekilde yeniden yapılandırıldı.
> Terraform dosyaları `modules/web-tier/` klasörüne taşındı.
> Lütfen **[README-terragrunt.md](README-terragrunt.md)** dosyasını takip edin.
>
> | Eski Yol | Yeni Yol |
> |----------|----------|
> | `main.tf`, `variables.tf` (root) | `modules/web-tier/*.tf` |
> | `cp terraform.tfvars.example terraform.tfvars` | Gerek yok — inputs `live/dev/web-tier/terragrunt.hcl` içinde |
> | `terraform init/plan/apply` | `terragrunt init/plan/apply` |

**Süre:** ~60 dakika
**Seviye:** Orta
**Kazanımlar:** `count`, `depends_on`, resource referansları, load balancer mimarisi

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
├── main.tf                   # Provider + Data sources
├── network.tf                # VPC, Subnet, Security Groups
├── compute.tf                # ECS instances (count kullanımı)
├── elb.tf                    # ELB, Listener, Pool, Members, EIP
├── variables.tf              # Değişken tanımları
├── outputs.tf                # Apply sonrası gösterilecek bilgiler
├── terraform.tfvars.example  # Örnek değişken dosyası
└── .gitignore                # State ve tfvars dosyalarını dışlar
```

---

## Workshop Adımları

### 1. Hazırlık (5 dk)

> **BU ADIM GEÇERSİZ — Terragrunt'a geçildi!**
> Aşağıdaki `cp` komutu artık çalışmaz çünkü `terraform.tfvars.example`
> `modules/web-tier/` klasörüne taşındı. Terragrunt kullanımında `terraform.tfvars`
> dosyasına gerek yoktur — lütfen **[README-terragrunt.md](README-terragrunt.md)**
> dosyasını takip edin.

```bash
# Repoyu klonla
git clone <repo-url>
cd tf-practices
```

~~`cp terraform.tfvars.example terraform.tfvars`~~ ← **YAPMAYIN — hata verir**

**Bunun yerine** çevre değişkenleri kullanın:

```powershell
# Windows PowerShell
$env:HW_ACCESS_KEY = "sizin_access_key"
$env:HW_SECRET_KEY = "sizin_secret_key"
$env:HW_REGION = "tr-west-1"
$env:TG_STATE_BUCKET = "workshop-terragrunt-state"
$env:TF_VAR_ecs_password = "Workshop@2024!"
```

```bash
# Linux / macOS
export HW_ACCESS_KEY="sizin_access_key"
export HW_SECRET_KEY="sizin_secret_key"
export HW_REGION="tr-west-1"
export TG_STATE_BUCKET="workshop-terragrunt-state"
export TF_VAR_ecs_password="Workshop@2024!"
```

Sonra **[README-terragrunt.md → Workshop Adımları](README-terragrunt.md#workshop-adımları)** bölümünden devam edin.

### 2. Terraform Init (3 dk)

```bash
terraform init
```

Terraform, Huawei Cloud provider'ını indirir ve `.terraform/` klasörünü oluşturur.

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

**Önemli sorular:**
- `+` (eklenecek), `~` (değişecek), `-` (silinecek) sembolleri ne anlama gelir?
- Neden bazı kaynaklar önce, bazıları sonra oluşturulacak?

---

### 5. Apply — Altyapıyı Oluştur (15-20 dk)

```bash
terraform apply
```

`yes` yazarak onaylayın. Terraform kaynakları oluşturmaya başlar.

> Toplam süre ~10-15 dakika (ECS başlangıç süresi dahil)

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
# Önce ECS'lerin IP'lerini öğren
terraform output ecs_private_ips

# SSH bağlantısı — ECS'lerin public IP'si yok!
# (ECS'ler sadece private IP'ye sahip, ELB üzerinden erişilir)
# Eğer doğrudan bağlanmak istersen ECS'e EIP ataması yapılmalı
```

---

### 7. Deneyler (5 dk)

Bunları denemeyi düşünün:

**A. ECS sayısını artır:**
```hcl
# terraform.tfvars
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
terraform state list           # Tüm kaynakları listele
terraform state show huaweicloud_elb_loadbalancer.main  # ELB detayı
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
terraform state list  # Boş çıktı

# Huawei Cloud Console'dan da kontrol et
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

---

## Sık Yapılan Hatalar

### "Error: No flavors found"
Bölgede uygun flavor bulunamadı. `ecs_flavor` değişkenini elle belirtin:
```hcl
ecs_flavor = "s6.small.1"
```

### "Error: image not found"
Bölgede Ubuntu 22.04 farklı isimde olabilir. Konsol'dan Public Images'a bakın.

### "Error 401: Unauthorized"
AK/SK yanlış veya bölge uyuşmuyor. `terraform.tfvars` dosyasını kontrol edin.

### Web sitesi açılmıyor
- nginx başlaması 2-3 dakika alabilir, bekleyin
- Security Group kurallarını kontrol edin
- ELB health monitor durumuna bakın (Console → ELB → Backend Groups)

---

## Kaynaklar

- [Huawei Cloud Terraform Provider Docs](https://registry.terraform.io/providers/huaweicloud/huaweicloud/latest/docs)
- [Provider GitHub](https://github.com/huaweicloud/terraform-provider-huaweicloud)
- [Terraform Dili Referansı](https://developer.hashicorp.com/terraform/language)
