terraform {
  required_providers {
    yandex = {
      source  = "yandex-cloud/yandex"
      version = "0.68.0"
    }
  }
}

provider "yandex" {
  token     = "AQAAAABbbCeCAATuwdgA0RU1k0v0okfVuCK0nKI"
  cloud_id  = "b1gqlrb7p6gvtjhuv1pe"
  folder_id = "b1ggp5ocil88ffdsudak"
  zone      = "ru-central1-a"
}

locals {
  folder_id = "b1ggp5ocil88ffdsudak"
}

// Создание сервис аккаунта
resource "yandex_iam_service_account" "sa" {
  folder_id = local.folder_id
  name      = "account"
}

// Назначение роли
resource "yandex_resourcemanager_folder_iam_member" "sa-admin" {
  folder_id = local.folder_id
  role      = "admin"
  member    = "serviceAccount:${yandex_iam_service_account.sa.id}"
}

// Создание статического ключа доступа
resource "yandex_iam_service_account_static_access_key" "sa-static-key" {
  service_account_id = yandex_iam_service_account.sa.id
  description        = "static access key for object storage"
}

// Создание Bucket
resource "yandex_storage_bucket" "my-bucket" {
  access_key = yandex_iam_service_account_static_access_key.sa-static-key.access_key
  secret_key = yandex_iam_service_account_static_access_key.sa-static-key.secret_key
  bucket = "mixa"
}

// Загрузка файла
resource "yandex_storage_object" "mixa-b" {
  access_key = yandex_iam_service_account_static_access_key.sa-static-key.access_key
  secret_key = yandex_iam_service_account_static_access_key.sa-static-key.secret_key
  bucket = "mixa"
  key    = "netology.png"
  source = "/15.3/netology.png"
}

// Добавление ключа
resource "yandex_kms_symmetric_key" "key-a" {
  name              = "my-key"
  description       = "key for backet"
  default_algorithm = "AES_128"
  rotation_period   = "8760h" // 1 год
}

// Шифрование бакета
resource "yandex_storage_bucket" "test" {
  bucket = "mixa"
  access_key = yandex_iam_service_account_static_access_key.sa-static-key.access_key
  secret_key = yandex_iam_service_account_static_access_key.sa-static-key.secret_key
  server_side_encryption_configuration {
    rule {
      apply_server_side_encryption_by_default {
        kms_master_key_id = yandex_kms_symmetric_key.key-a.id
        sse_algorithm     = "aws:kms"
      }
    }
  }
}
