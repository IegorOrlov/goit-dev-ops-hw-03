# Підключаємо модуль для S3 та DynamoDB
module "s3_backend" {
  source      = "./modules/s3-backend" # Шлях до модуля
  bucket_name = var.bucket_name       # Унікальне ім'я S3-бакета
  table_name  = "terraform-locks"     # Ім'я DynamoDB
}

# Підключаємо модуль для VPC
module "vpc" {
  source             = "./modules/vpc"
  vpc_cidr_block     = "10.0.0.0/16"
  public_subnets     = ["10.0.1.0/24", "10.0.2.0/24", "10.0.3.0/24"]
  private_subnets    = ["10.0.4.0/24", "10.0.5.0/24", "10.0.6.0/24"]
  availability_zones = ["us-west-2a", "us-west-2b", "us-west-2c"]
  vpc_name           = "vpc"
}

# Підключаємо модуль для ECR
module "ecr" {
  source                = "./modules/ecr"
  ecr_name              = "lesson-5-ecr"
  scan_on_push          = true
  allowed_principal_arn = "arn:aws:iam::412930559924:user/terraform-student"
}
