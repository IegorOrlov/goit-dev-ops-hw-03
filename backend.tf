# Спочатку створіть S3-бакет і таблицю з локальним state.
# Потім замініть placeholder точним значенням bucket_name, розкоментуйте
# блок і перенесіть state за інструкцією в README.md.
terraform {
  backend "s3" {
    bucket         = "goit-tfstate-412930559924-lesson-5"
    key            = "lesson-5/terraform.tfstate"
    region         = "us-west-2"
    dynamodb_table = "terraform-locks"
    encrypt        = true
  }
}
