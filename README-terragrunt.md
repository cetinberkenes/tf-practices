# Huawei Cloud + Terragrunt Workshop
## Fikir 3: ELB + ECS — Terragrunt ile Yönetim

**Süre:** ~75 dakika
**Seviye:** Orta-İleri
**Kazanımlar:** Terragrunt temelleri, DRY prensibi, remote state, modül yönetimi

---

## Terragrunt Nedir?

Terragrunt, Terraform için ince bir sarmalayıcı (wrapper) araçtır.

```
Kullanıcı → terragrunt plan/apply → Terraform plan/apply
```

**Terraform'un eksikliklerini giderir:**

| Problem | Terragrunt Çözümü |
|---------|-----------------|
| Her modülde aynı provider bloğunu yaz | `generate` ile bir kez yaz, herkese uygula |
| Her modülde backend konfigürasyonu yaz | `remote_state` ile otomatik oluştur |
| State dosyaları yerel kalır | OBS'ye (bulut) otomatik yükle |
| Modüller arası bağımlılık zor | `dependency` bloğu ile kolay yönet |

---

## Dosya Yapısı

```
tf-practices/
├── modules/
│   └── web-tier/               ← Yeniden kullanılabilir Terraform modülü
│       ├── main.tf             ← Data sources + locals (provider YOK!)
│       ├── network.tf          ← VPC, Subnet, Security Groups
│       ├── compute.tf          ← ECS instances (count ile)
│       ├── elb.tf              ← ELB, EIP, Listener, Pool, Members
│       ├── variables.tf        ← Değişkenler (AK/SK YOK — Terragrunt yönetir)
│       └── outputs.tf          ← Çıktılar
│
└── live/
    ├── terragrunt.hcl          ← ROOT: Provider + Remote State (bir kez yaz)
    └── dev/
        └── web-tier/
            └── terragrunt.hcl  ← DEV: Module source + inputs
```

**Temel fark — Terraform vs Terragrunt:**

```hcl
# TERRAFORm (her modülde tekrar yazılır)
provider "huaweicloud" {        terraform {
  region     = var.region         backend "s3" {
  access_key = var.access_key       bucket = "my-bucket"
  secret_key = var.secret_key       key    = "dev/web.tfstate"
}                                   ...
                                  }
                                }

# TERRAGRUNT (bir kez tanımlanır, tüm modüller miras alır)
generate "provider" { ... }     remote_state { backend = "s3" ... }
```

---

## Ön Gereksinimler

- [ ] [Terraform](https://developer.hashicorp.com/terraform/install) >= 1.3.0
- [ ] [Terragrunt](https://terragrunt.gruntwork.io/docs/getting-started/install/) >= 0.50.0
- [ ] Huawei Cloud hesabı + AK/SK
- [ ] OBS bucket (terraform state için)

### Terragrunt Kurulum

```bash
# Linux/macOS
brew install terragrunt

# Veya manuel
curl -Lo terragrunt https://github.com/gruntwork-io/terragrunt/releases/latest/download/terragrunt_linux_amd64
chmod +x terragrunt
sudo mv terragrunt /usr/local/bin/

# Versiyon kontrolü
terragrunt --version
```

### OBS Bucket Oluştur (Remote State İçin)

1. Huawei Cloud Console → **OBS** → Bucket Oluştur
2. Bucket adı: `workshop-terragrunt-state` (benzersiz olmalı!)
3. Bölge: `tr-west-1`
4. Varsayılan ayarlar yeterli

---

## Çevre Değişkenleri

Kimlik bilgilerini **asla** kod içine yazmayın. Çevre değişkeni kullanın:

```bash
# ~/.bashrc veya ~/.zshrc dosyasına ekle
export HW_ACCESS_KEY="sizin_access_key_buraya"
export HW_SECRET_KEY="sizin_secret_key_buraya"
export HW_REGION="tr-west-1"
export TG_STATE_BUCKET="workshop-terragrunt-state"   # OBS bucket adı
export TF_VAR_ecs_password="Workshop@2024!"

# Terminale uygula
source ~/.bashrc
```

---

## Workshop Adımları

### 1. Yapıyı İncele (10 dk)

```bash
# Repo kökünden başla
cd tf-practices

# Modül yapısına bak
ls -la modules/web-tier/
ls -la live/
ls -la live/dev/web-tier/
```

**Önemli sorular:**
- `modules/web-tier/main.tf` içinde provider bloğu var mı? Neden?
- `live/terragrunt.hcl` ile `live/dev/web-tier/terragrunt.hcl` farkı ne?
- `include "root"` ne yapıyor?

### 2. Root Konfigürasyonu İncele

```bash
cat live/terragrunt.hcl
```

**Dikkat edilecek noktalar:**
- `generate "provider"` → `provider.tf` dosyasını nereye yazar?
- `remote_state` → OBS endpoint nasıl oluşturulmuş?
- `path_relative_to_include()` → Ne döndürür?
- `get_env()` → Env variable yoksa ne olur?

### 3. Ortam Konfigürasyonunu İncele

```bash
cat live/dev/web-tier/terragrunt.hcl
```

**Dikkat edilecek noktalar:**
- `find_in_parent_folders()` → Nasıl çalışıyor?
- `get_repo_root()` → Neden absolute path yerine bu kullanıldı?
- `inputs` bloğu → `terraform.tfvars`'tan farkı ne?

### 4. Init

```bash
cd live/dev/web-tier
terragrunt init
```

**Terragrunt init ne yapar?**
1. `.terragrunt-cache/` klasörü oluşturur
2. Kaynak modülü buraya kopyalar
3. `provider.tf` ve `backend.tf` dosyalarını generate eder
4. `terraform init` çalıştırır (provider indirir, backend kurar)

**Generate edilen dosyaları gör:**
```bash
find .terragrunt-cache -name "provider.tf" -o -name "backend.tf" | head -5
cat $(find .terragrunt-cache -name "provider.tf" | head -1)
```

### 5. Plan

```bash
terragrunt plan
```

Terraform plan ile aynı çıktıyı verir, ek olarak Terragrunt işlemlerini gösterir.

**Fark:**
```
TERRAGRUNT: Generating provider.tf...
TERRAGRUNT: Generating backend.tf...
TERRAGRUNT: Running command: terraform plan
```

### 6. Apply

```bash
terragrunt apply
```

`yes` ile onaylayın.

**Apply sonrası OBS'yi kontrol et:**
```
Console → OBS → workshop-terragrunt-state bucket
→ dev/web-tier/terraform.tfstate dosyasını göreceksiniz!
```

State artık yerel değil, bulutta!

### 7. Test

```bash
# Web URL'yi al
terragrunt output web_url

# Tarayıcıda aç ve yenile — farklı sunucular!
curl $(terragrunt output -raw elb_public_ip)
```

### 8. State Komutları

```bash
# State listesi (OBS'deki state'i okur)
terragrunt state list

# Belirli kaynağı incele
terragrunt state show huaweicloud_elb_loadbalancer.main

# Output sorgula
terragrunt output ecs_private_ips
```

### 9. Destroy

```bash
terragrunt destroy
```

---

## Gelişmiş Özellikler (Bonus)

### A. Staging Ortamı Ekle

```bash
mkdir -p live/staging/web-tier
cp live/dev/web-tier/terragrunt.hcl live/staging/web-tier/terragrunt.hcl
```

`live/staging/web-tier/terragrunt.hcl` dosyasını düzenle:
```hcl
inputs = {
  prefix         = "staging-workshop"
  ecs_count      = 3          # Staging'de daha fazla sunucu
  bandwidth_size = 10         # Daha yüksek bant genişliği
  ecs_password   = get_env("TF_VAR_ecs_password", "")
}
```

Aynı modülü farklı parametrelerle kullanın:
```bash
cd live/staging/web-tier
terragrunt apply
```

### B. Dependency Bloğu

Birden fazla modülünüz olduğunda birbirinden output alabilirsiniz:

```hcl
# live/dev/app-server/terragrunt.hcl
dependency "network" {
  config_path = "../network"
}

inputs = {
  vpc_id    = dependency.network.outputs.vpc_id
  subnet_id = dependency.network.outputs.subnet_id
}
```

### C. Tümünü Tek Komutla Çalıştır

```bash
# live/ altındaki TÜM modülleri apply et
cd live
terragrunt run-all apply

# TÜM modülleri destroy et
terragrunt run-all destroy
```

---

## Komut Karşılaştırması

| Terraform | Terragrunt |
|-----------|-----------|
| `terraform init` | `terragrunt init` |
| `terraform plan` | `terragrunt plan` |
| `terraform apply` | `terragrunt apply` |
| `terraform destroy` | `terragrunt destroy` |
| `terraform output` | `terragrunt output` |
| `terraform state list` | `terragrunt state list` |
| *(yok)* | `terragrunt run-all apply` |

---

## Sık Yapılan Hatalar

### "Error: No OBS bucket found"
OBS bucket oluşturulmamış. Console'dan oluşturun, `TG_STATE_BUCKET` ile aynı ismi kullanın.

### "Error: HW_ACCESS_KEY not set"
Çevre değişkenleri set edilmemiş:
```bash
echo $HW_ACCESS_KEY   # Boş mu?
export HW_ACCESS_KEY="sizin_key"
```

### "Error: find_in_parent_folders() — parent terragrunt.hcl bulunamadı"
Komutları `live/dev/web-tier/` içinden çalıştırdığınızdan emin olun.

### ".terragrunt-cache/ çok büyüdü"
```bash
terragrunt clean   # Cache'i temizle
```

---

## Kaynaklar

- [Terragrunt Docs](https://terragrunt.gruntwork.io/docs/)
- [Terragrunt GitHub](https://github.com/gruntwork-io/terragrunt)
- [Huawei Cloud Provider](https://registry.terraform.io/providers/huaweicloud/huaweicloud/latest/docs)
- [OBS S3 Uyumluluğu](https://support.huaweicloud.com/intl/en-us/ugobs-obs/obs_03_0005.html)
