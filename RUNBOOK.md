# Terraform Öğrenme Runbook
### HashiCorp Terraform Associate — Hands-on Rehber

**Süre:** ~4-5 saat (kendi hızınızda)
**Ön koşul:** Terminal kullanımı, temel programlama mantığı
**Bulut hesabı gerekmez:** Lab 01-10 tamamen yerelde çalışır

---

## Hazırlık

```bash
# Terraform kurulumunu doğrula
terraform version
# → Terraform v1.x.x

# Lab klasörüne gir
cd tf-practices/labs
```

> Her lab kendi klasöründe bağımsızdır. `terraform init` her klasörde ayrı çalıştırılır.

---

## Lab 01 — Provider ve Init

**Klasör:** `labs/01-provider-init/`
**Konu:** Provider nedir, `terraform init` ne yapar

### Provider Nedir?

Terraform kendi başına hiçbir şey oluşturamaz. Bulut sağlayıcısıyla (AWS, Azure, Huawei Cloud…) veya başka bir sistemle konuşmak için **provider** eklentisi kullanır.

```
Terraform kodu  →  Provider  →  Huawei Cloud API
                               AWS API
                               local dosya sistemi
                               ...
```

Provider'lar `required_providers` bloğunda tanımlanır:

```hcl
terraform {
  required_providers {
    huaweicloud = {
      source  = "huaweicloud/huaweicloud"  # registry.terraform.io'daki adresi
      version = ">= 1.60.0"               # minimum versiyon
    }
  }
}
```

### terraform init

`terraform init`, provider eklentisini internetten indirip `.terraform/` klasörüne kurar.

```bash
cd labs/01-provider-init
terraform init
```

**Ne oluşur?**
```
.terraform/
└── providers/
    └── registry.terraform.io/
        └── hashicorp/
            ├── local/2.x.x/...
            └── random/3.x.x/...

.terraform.lock.hcl   ← provider versiyonlarını kilitler (git'e commit edin!)
```

**.terraform.lock.hcl nedir?**
Takım arkadaşlarınızın da aynı provider versiyonunu kullanmasını garanti eder. Git'e commit edilmesi önerilir.

### Alıştırma

```bash
terraform init

# Oluşan dosyaları incele
ls -la
ls .terraform/providers/registry.terraform.io/hashicorp/

# Lock dosyasını oku
cat .terraform.lock.hcl
```

**Kontrol soruları:**
1. `.terraform/` klasörü ne içeriyor?
2. `.terraform.lock.hcl` dosyası neden önemli?
3. Provider'ı değiştirmek isteseydiniz `init`'i tekrar çalıştırmanız gerekir mi?

---

## Lab 02 — Plan, Apply, Destroy

**Klasör:** `labs/02-plan-apply-destroy/`
**Konu:** Terraform'un temel iş akışı

### Temel İş Akışı

```
init → plan → apply → (değişiklik) → plan → apply → destroy
```

### terraform fmt ve validate

Koda dokunmadan önce her zaman bu ikisini çalıştırın:

```bash
terraform fmt       # Kodu otomatik biçimlendirir (hizalama, girintileme)
terraform validate  # Sözdizimi hatalarını kontrol eder, API çağrısı yapmaz
```

### terraform plan

Terraform'un yapacaklarını gösterir, **hiçbir şey oluşturmaz.**

```bash
terraform plan
```

Çıktıdaki semboller:
```
+ create    → bu kaynak oluşturulacak
~ update    → bu kaynak güncellencek (yıkılmadan)
- destroy   → bu kaynak silinecek
-/+ replace → silinip yeniden oluşturulacak (dikkat!)
```

`(known after apply)` → değer ancak kaynak oluşturulduktan sonra bilinecek

### terraform apply

```bash
terraform apply
```

`yes` yazarak onaylayın. Terraform kaynakları oluşturur ve `terraform.tfstate` dosyasını günceller.

`-auto-approve` ile onay adımını atlayabilirsiniz (CI/CD'de kullanılır):
```bash
terraform apply -auto-approve
```

### terraform destroy

```bash
terraform destroy
```

Terraform'un oluşturduğu tüm kaynakları siler. Ters sırayla siler (bağımlılıklar korunur).

### Alıştırma

```bash
cd labs/02-plan-apply-destroy

terraform fmt
terraform validate
terraform plan       # Kaç kaynak oluşacak?
terraform apply

ls cikti/            # Dosyalar oluştu mu?
cat cikti/config.txt

terraform destroy
ls cikti/            # Dosyalar silindi mi?
```

**Kontrol soruları:**
1. `plan` ile `apply` arasındaki fark nedir?
2. `destroy` sonrası `cikti/` klasörü neden boş değil? (Klasör silinmedi, sadece Terraform kaynakları silindi)
3. `-auto-approve` ne zaman kullanılır, ne zaman kullanılmamalı?

---

## Lab 03 — State (Durum Dosyası)

**Klasör:** `labs/03-state/`
**Konu:** State nedir, state komutları

### State Nedir?

Terraform, oluşturduğu kaynakları **`terraform.tfstate`** dosyasında takip eder.

```
Terraform kodu   →  apply  →  Gerçek altyapı
     ↓                              ↑
terraform.tfstate  ←  senkronize  ←
```

**State olmadan ne olurdu?**
Terraform her `apply`'da mevcut kaynakların var olup olmadığını bilemez ve hepsini tekrar oluşturmaya çalışırdı.

**State dosyası neler içerir?**
- Her kaynağın ID'si (cloud tarafında)
- Kaynağın tüm özellikleri
- Bağımlılık bilgisi

> **Uyarı:** `terraform.tfstate` dosyasını elle düzenlemeyin! İçinde AK/SK gibi hassas veriler olabilir, `.gitignore`'a ekleyin.

### State Komutları

```bash
# Tüm kaynakları listele
terraform state list

# Belirli bir kaynağın detaylarını göster
terraform state show <kaynak_adresi>

# Kaynağı state'den çıkar (buluttan SİLMEZ, sadece takibi bırakır)
terraform state rm <kaynak_adresi>

# Kaynağı yeniden adlandır
terraform state mv <eski_ad> <yeni_ad>

# Cloud'daki gerçek durumu state ile senkronize et
terraform refresh
```

### terraform.tfstate vs terraform.tfstate.backup

Her `apply` sonrası önceki state, `.backup` dosyasına kopyalanır. Acil geri alma için kullanılabilir.

### Alıştırma

```bash
cd labs/03-state
terraform init && terraform apply -auto-approve

# Kaynakları incele
terraform state list
terraform state show random_pet.sunucu_adi
terraform state show local_file.sunucu_config

# State dosyasını ham JSON olarak oku
cat terraform.tfstate

# Bir kaynağı state'den çıkar
terraform state rm local_file.env_dosya

# Şimdi plan'a bak — env_dosya "yeni kaynak" gibi görünür
terraform plan
```

**Kontrol soruları:**
1. `terraform state rm` komutu dosyayı diskten siliyor mu?
2. State'i silerseniz ne olur? (`rm terraform.tfstate` → `terraform plan` deneyin)
3. Remote backend neden kullanılır? (Takım çalışmasında state dosyası nerede durmalı?)

---

## Lab 04 — Variables (Değişkenler)

**Klasör:** `labs/04-variables/`
**Konu:** Değişken tipleri, tfvars, validation, sensitive

### Variable Tanımlama

```hcl
variable "port" {
  description = "Uygulama portu"   # zorunlu değil ama iyi pratik
  type        = number              # string, number, bool, list, map, object...
  default     = 8080                # yoksa zorunlu değişken olur

  validation {
    condition     = var.port >= 1024
    error_message = "Port 1024'ten büyük olmalıdır."
  }
}
```

### Değişken Tipleri

| Tip | Örnek |
|-----|-------|
| `string` | `"dev"` |
| `number` | `8080` |
| `bool` | `true` |
| `list(string)` | `["a", "b", "c"]` |
| `map(string)` | `{ key = "value" }` |
| `object({...})` | `{ port = number, ad = string }` |
| `any` | Her şey (önerilmez) |

### Değer Atama Yöntemleri (Öncelik Sırası)

En yüksek öncelik en üstte:

```
1. -var flag           terraform apply -var="port=3000"
2. -var-file flag      terraform apply -var-file="prod.tfvars"
3. *.auto.tfvars       otomatik yüklenir
4. terraform.tfvars    otomatik yüklenir
5. Ortam değişkeni     TF_VAR_port=3000 terraform apply
6. default değeri      variable bloğundaki default
7. (interaktif giriş)  terminal'de sorulur
```

### sensitive Değişkenler

```hcl
variable "db_password" {
  type      = string
  sensitive = true   # plan/apply çıktısında (sensitive) görünür, değer gizlenir
}
```

### Alıştırma

```bash
cd labs/04-variables
cp terraform.tfvars.example terraform.tfvars
# terraform.tfvars'ı düzenleyin

terraform init && terraform validate

# Farklı yöntemlerle değer vermeyi deneyin:
terraform plan                                  # tfvars'tan okur
terraform plan -var="environment=prod"          # flag ile override
TF_VAR_port=9090 terraform plan                 # env var ile

# Validation'ı test edin:
terraform plan -var="environment=test"          # → hata vermeli
terraform plan -var="port=80"                   # → hata vermeli (< 1024)

terraform apply
cat cikti/app.conf
cat cikti/.env
```

**Kontrol soruları:**
1. `default` değeri olmayan bir değişkene değer vermezseniz ne olur?
2. `sensitive = true` olan değişkeni `terraform output`'ta görebilir misiniz?
3. `terraform.tfvars` dosyasını git'e commit etmemek neden önemli?

---

## Lab 05 — Outputs

**Klasör:** `labs/05-outputs/`
**Konu:** Output tanımlama, sorgulama, sensitive output

### Output Nedir?

`apply` sonrası gösterilmesini istediğiniz değerler. Modüller arası değer aktarımında da kullanılır.

```hcl
output "web_url" {
  description = "Web sitesi adresi"
  value       = "http://${huaweicloud_vpc_eip.main.address}"
  sensitive   = false   # varsayılan
}
```

### Output Komutları

```bash
terraform output                    # tüm outputlar
terraform output sunucu_adi         # tek output
terraform output -json              # JSON formatında (script'lerde kullanışlı)
terraform output -raw sunucu_adi    # sadece değer, tırnak yok
```

### Alıştırma

```bash
cd labs/05-outputs
terraform init && terraform apply -auto-approve

terraform output
terraform output -json
terraform output -raw sunucu_adi
terraform output baglanti_adresi

# sensitive output
terraform output api_key     # değeri gösterir (terminaldeyseniz)
terraform output -json | cat # JSON'da da görünür
```

**Kontrol soruları:**
1. Output'u başka bir modülde nasıl kullanırsınız?
2. `sensitive = true` olan output, `terraform output` komutunda göster mi?
3. `terraform output -json` ne işe yarar?

---

## Lab 06 — Locals ve Built-in Functions

**Klasör:** `labs/06-locals-functions/`
**Konu:** locals bloğu, string/map/liste fonksiyonları

### Locals Nedir?

`variable` dışarıdan değer alır. `locals` ise kodun içinde hesaplanan, **dışarıdan değiştirilemeyen** değerlerdir.

```hcl
locals {
  isim_prefix = "${var.proje}-${var.ortam}"  # "workshop-dev"
  ortak_tags  = merge(var.ekstra_tags, { ManagedBy = "terraform" })
}

# Kullanım: local.<ad>
resource "..." "..." {
  name = local.isim_prefix
}
```

### Sık Kullanılan Fonksiyonlar

```hcl
# String
upper("dev")                          # "DEV"
lower("DEV")                          # "dev"
format("%s-%s", "web", "01")          # "web-01"
replace("web-server", "-", "_")       # "web_server"
trimspace("  merhaba  ")              # "merhaba"

# Liste
length(["a","b","c"])                 # 3
element(["a","b","c"], 1)             # "b"
concat(["a"], ["b","c"])              # ["a","b","c"]
flatten([["a","b"],["c"]])            # ["a","b","c"]

# Map
merge({a=1}, {b=2})                   # {a=1, b=2}
keys({a=1, b=2})                      # ["a","b"]
values({a=1, b=2})                    # [1,2]
lookup({a="x"}, "a", "default")       # "x"

# Tip dönüşümü
toset(["a","b","a"])                  # {"a","b"}  (tekrar yok)
tolist(toset(["b","a"]))              # ["a","b"]
tonumber("42")                        # 42

# Network
cidrsubnet("10.0.0.0/16", 8, 0)      # "10.0.0.0/24"
cidrsubnet("10.0.0.0/16", 8, 1)      # "10.0.1.0/24"

# JSON
jsonencode({key = "value"})           # "{\"key\":\"value\"}"
jsondecode("{\"key\":\"value\"}")     # {key = "value"}
```

### Alıştırma

```bash
cd labs/06-locals-functions
terraform init && terraform apply

cat cikti/locals_raporu.txt   # Fonksiyonların sonuçlarını görün

# Terraform console ile interaktif test
terraform console
> upper("merhaba")
> merge({a="x"}, {b="y"})
> cidrsubnet("10.0.0.0/16", 8, 5)
> length(["a","b","c"])
> exit
```

> `terraform console` fonksiyonları interaktif test etmek için çok kullanışlıdır!

**Kontrol soruları:**
1. `variable` ile `locals` arasındaki fark nedir?
2. `toset()` neden kullanılır?
3. `cidrsubnet("10.0.0.0/8", 8, 3)` ne döndürür?

---

## Lab 07 — Data Sources

**Klasör:** `labs/07-data-sources/`
**Konu:** resource vs data, mevcut kaynakları okuma

### resource vs data Farkı

```hcl
# resource → Terraform bu kaynağı OLUŞTURUR ve yönetir
resource "local_file" "yeni_dosya" {
  filename = "yeni.txt"
  content  = "merhaba"
}

# data → Terraform mevcut bir kaynağı OKUR, dokunmaz
data "local_file" "mevcut_dosya" {
  filename = "/etc/hostname"
}
```

**Gerçek senaryolar:**

```hcl
# Bölgedeki mevcut Ubuntu imajını bul (oluşturma!)
data "huaweicloud_images_image" "ubuntu" {
  name        = "Ubuntu 22.04 server 64bit"
  most_recent = true
}

# Elde edilen imajı ECS oluştururken kullan
resource "huaweicloud_compute_instance" "web" {
  image_id = data.huaweicloud_images_image.ubuntu.id
  ...
}
```

### Referans Sözdizimi

```
resource → huaweicloud_compute_instance.web.id
data     → data.huaweicloud_images_image.ubuntu.id
           ↑
           "data." öneki zorunlu
```

### Alıştırma

```bash
cd labs/07-data-sources
terraform init && terraform apply

cat cikti/kaynak.json     # resource ile oluşturulan
cat cikti/islenmis.txt    # data source ile okunan ve işlenen

terraform output dosya_icerik
```

**Kontrol soruları:**
1. `data` bloğu `destroy` sırasında kaynağı siler mi?
2. `data` kaynağına `depends_on` ne zaman gerekir?
3. Dışarıdan yönetilen (Terraform dışı) bir kaynağı Terraform'a nasıl entegre edersiniz?

---

## Lab 08 — count ve for_each

**Klasör:** `labs/08-count-foreach/`
**Konu:** Birden fazla kaynak oluşturma

### count

```hcl
resource "local_file" "log" {
  count    = 3
  filename = "log-${count.index}.txt"  # log-0.txt, log-1.txt, log-2.txt
  content  = "Dosya ${count.index + 1}\n"
}

# Erişim: local_file.log[0], local_file.log[1], ...
# Tümü:   local_file.log[*].filename
```

### for_each

```hcl
variable "servisler" {
  default = {
    web = { port = 80 }
    api = { port = 8080 }
  }
}

resource "local_file" "config" {
  for_each = var.servisler

  filename = "${each.key}.conf"          # web.conf, api.conf
  content  = "port=${each.value.port}\n"
}

# Erişim: local_file.config["web"], local_file.config["api"]
```

### count vs for_each — Ne Zaman Hangisi?

| Durum | Öneri |
|-------|-------|
| Kaynaklar birbirinin aynısı, sadece sayı değişiyor | `count` |
| Her kaynağın farklı özelliği var | `for_each` ✓ |
| Listeden ortadaki eleman silinebilir | `for_each` ✓ |
| Üretim altyapısı | `for_each` ✓ |

**count'un tehlikesi:**
```
["dev", "staging", "prod"]  →  index: 0, 1, 2

"staging" silinirse:
["dev", "prod"]             →  index: 0, 1

Terraform: index[1] = staging → DESTROY
           index[1] = prod   → CREATE
→ prod sunucusu yıkılıp yeniden oluşturulur!
```

### Alıştırma

```bash
cd labs/08-count-foreach
terraform init && terraform apply -auto-approve

ls cikti/count/     # count ile oluşturulan dosyalar
ls cikti/foreach/   # for_each ile oluşturulan dosyalar
ls cikti/ortamlar/  # toset ile for_each

terraform state list   # Adres formatlarına dikkat edin

# count: local_file.count_dosya[0]
# for_each: local_file.foreach_dosya["web"]

# for_each'ten eleman silme testi:
# variables.tf içinde "api" servisini silin
# terraform plan  → sadece api silinir, web ve db etkilenmez
```

**Kontrol soruları:**
1. `for_each` ile `toset()` birlikte neden kullanılır?
2. `count` ile oluşturulan kaynağın state'deki adres formatı nedir?
3. `for_each = var.servisler` ile `for_each = toset(var.servisler)` farkı nedir?

---

## Lab 09 — Modules (Modüller)

**Klasör:** `labs/09-modules/`
**Konu:** Modül oluşturma, çağırma, input/output

### Modül Nedir?

Birden fazla yerde kullanılacak Terraform kodunu bir klasöre koyup yeniden kullanılabilir hale getirme.

```
labs/09-modules/
├── main.tf                    ← root modül (çağıran)
└── modules/
    └── server/                ← child modül (çağrılan)
        ├── main.tf
        ├── variables.tf       ← modülün input'ları
        └── outputs.tf         ← modülün output'ları
```

### Modül Çağırma

```hcl
module "web" {
  source = "./modules/server"   # kaynak: yerel klasör, Git URL, Terraform Registry

  # variables.tf'deki değişkenlere değer verilir
  sunucu_adi = "web-01"
  port       = 80
}

# Modülün output'una erişim
output "web_id" {
  value = module.web.sunucu_id   # module.<ad>.<output_adı>
}
```

### Modül Kaynakları — Source Seçenekleri

```hcl
# Yerel klasör
source = "./modules/server"

# Git
source = "git::https://github.com/org/repo.git//modules/server?ref=v1.0"

# Terraform Registry (resmi)
source  = "terraform-aws-modules/vpc/aws"
version = "~> 5.0"
```

> Her yeni `source` eklendiğinde `terraform init` tekrar çalıştırılmalıdır.

### Alıştırma

```bash
cd labs/09-modules
terraform init    # modül de init edilir
terraform apply -auto-approve

ls cikti/
cat cikti/web-01.conf
cat cikti/api-01.conf

terraform output tum_sunucular

# Modül içi kaynakları state'de incele
terraform state list
# → module.web_sunucu.random_id.sunucu_id
# → module.web_sunucu.local_file.sunucu_config
```

**Kontrol soruları:**
1. Bir modülün `variables.tf`'i yoksa input nasıl geçilir?
2. Modülde tanımlanmayan output'a root'tan erişebilir misiniz?
3. `terraform init` neden her `source` değişikliğinde gerekli?

---

## Lab 10 — Lifecycle

**Klasör:** `labs/10-lifecycle/`
**Konu:** create_before_destroy, ignore_changes, prevent_destroy

### lifecycle Bloğu

Her `resource` içine eklenebilir:

```hcl
resource "..." "..." {
  # ...kaynak özellikleri...

  lifecycle {
    create_before_destroy = bool
    prevent_destroy       = bool
    ignore_changes        = [alan1, alan2]
    replace_triggered_by  = [baska_kaynak]
  }
}
```

### Ne Zaman Ne Kullanılır?

| Argüman | Ne zaman? |
|---------|-----------|
| `create_before_destroy = true` | Kesinti kabul edilemez (load balancer, DNS) |
| `prevent_destroy = true` | Kritik veriler silinmemeli (prod DB, EIP) |
| `ignore_changes = [tags]` | Konsol'dan elle değiştirilen alanlar Terraform'u tetiklemesin |
| `replace_triggered_by` | Başka kaynak değişince bu da yenilensin |

### Alıştırma

```bash
cd labs/10-lifecycle
terraform init && terraform apply

cat cikti/app.log

# ignore_changes testi:
# cikti/app.log dosyasını elle düzenleyin
# terraform plan  → değişiklik görmemeli (ignore_changes)

# prevent_destroy testi:
# terraform destroy  → kritik.dat için hata verecek
# önce prevent_destroy = false yapın, sonra destroy

# replace_triggered_by testi:
terraform apply -var="etiket=v2"  # tetiklenen.txt yenilenir
```

**Kontrol soruları:**
1. `prevent_destroy = true` olan bir kaynağı silmek için ne yapmanız gerekir?
2. `create_before_destroy` olmadan kaynak güncellenince ne olur?
3. Konsoldan elle eklediğiniz bir tag'in Terraform plan'ı tetiklememesini nasıl sağlarsınız?

---

## Bonus: terraform import

Terraform dışında oluşturulmuş kaynakları Terraform yönetimine almak için kullanılır.

```bash
# 1. Önce .tf dosyasında kaynak tanımını yazın (boş)
resource "huaweicloud_networking_secgroup" "imported" {
  # alanlar dolu olmak zorunda değil — import sonrası dolduracaksınız
}

# 2. Import komutu
terraform import huaweicloud_networking_secgroup.imported <kaynak-id>

# 3. State'de görünecek — tf kodunu state'e göre doldurun
terraform state show huaweicloud_networking_secgroup.imported

# 4. Plan temiz çıkana kadar tf kodunu düzeltin
terraform plan  # → "No changes" görmeli
```

> Terraform 1.5+ ile `import` bloğu da kullanılabilir:
> ```hcl
> import {
>   to = huaweicloud_networking_secgroup.imported
>   id = "<kaynak-id>"
> }
> ```

---

## Özet: Associate Exam Konuları

| Konu | Lab | Durum |
|------|-----|-------|
| Provider ve init | 01 | |
| fmt, validate, plan, apply, destroy | 02 | |
| State — list, show, rm, mv, refresh | 03 | |
| Variables — tipler, tfvars, validation, sensitive | 04 | |
| Outputs — json, raw, sensitive | 05 | |
| Locals ve built-in functions | 06 | |
| Data sources | 07 | |
| count ve for_each | 08 | |
| Modules — source, input, output | 09 | |
| Lifecycle | 10 | |
| terraform import | Bonus | |
| Remote backend | (*) | |
| terraform workspace | (*) | |

> (*) Remote backend ve workspace için bulut hesabı veya Terraform Cloud üyeliği gerekir.

---

## Kaynaklar

- [Terraform Language Docs](https://developer.hashicorp.com/terraform/language)
- [Built-in Functions Referansı](https://developer.hashicorp.com/terraform/language/functions)
- [Associate Exam Study Guide](https://developer.hashicorp.com/terraform/tutorials/certification-003/associate-study-003)
- [Huawei Cloud Provider Docs](https://registry.terraform.io/providers/huaweicloud/huaweicloud/latest/docs)
