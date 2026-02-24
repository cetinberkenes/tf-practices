terraform {
  required_providers {
    random = { source = "hashicorp/random", version = ">= 3.5.0" }
    local  = { source = "hashicorp/local", version = ">= 2.4.0" }
  }
}

resource "random_string" "api_key" {
  length  = 32
  special = false
}

resource "random_pet" "sunucu" {
  length = 2
}

resource "random_integer" "port" {
  min = 3000
  max = 9000
}

resource "local_file" "bilgi" {
  filename = "${path.module}/cikti/bilgi.txt"
  content  = "sunucu=${random_pet.sunucu.id} port=${random_integer.port.result}\n"
}
