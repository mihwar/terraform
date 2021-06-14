terraform {
  backend "s3" {
    bucket    = "terraform-unr-state"
    key       = "stage/data-stores/mysql/terraform.tfstate"
    region    = "us-east-2"

    # Замените это именем своей таблицы DynamoDB!
    dynamodb_table = "terraform-up-and-running-locks"
    encrypt  = true
    } 
}

provider "aws" {
  region = "us-east-2"
}

resource "aws_db_instance" "example" {
  identifier_prefix  = "terraform-up-and-running"
  engine            = "mysql"
  allocated_storage = 10
  instance_class    = "db.t2.micro"
  name              = "example_database"
  username          = "admin"
  password          = var.db_password
}

