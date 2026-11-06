# Спочатку створіть S3-бакет і таблицю з локальним state.
# Потім замініть placeholder точним значенням bucket_name, розкоментуйте
# блок і перенесіть state за інструкцією в README.md.
# terraform {
#   backend "s3" {
#     bucket         = "REPLACE_WITH_YOUR_UNIQUE_BUCKET_NAME"
#     key            = "lesson-5/terraform.tfstate"
#     region         = "us-west-2"
#     dynamodb_table = "terraform-locks"
#     encrypt        = true
#   }
# }
