terraform {
  backend "s3" {
    bucket = "terraform-unr-state"
    key = "global/s3/terraform.tfstate"
    region = "us-east-2"
    dynamodb_table = "terraform-up-and-running-locks"
    encrypt = true
  }
}

provider "aws" {
  region = "us-east-2"
}

resource "aws_s3_bucket" "terraform_state" {
  bucket = "terraform-unr-state"

  # Предотвращаем случайное удаление этого бакета S3
  lifecycle {
    prevent_destroy = true
  }
  
  # Включаем управление версиями, чтобы вы могли просматривать
  # всю историю ваших файлов состояния
  versioning {
    enabled = true
  }

  # Включаем шифрование по умолчанию на стороне сервера
  server_side_encryption_configuration {
    rule {
      apply_server_side_encryption_by_default {
        sse_algorithm = "AES256"
      }
    }
  }
}

resource "aws_dynamodb_table" "terraform_locks" {
  name = "terraform-up-and-running-locks"
  billing_mode = "PAY_PER_REQUEST"
  hash_key = "LockID"

  attribute {
   name = "LockID"
   type = "S"
  }
}

