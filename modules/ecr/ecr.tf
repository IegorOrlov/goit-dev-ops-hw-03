resource "aws_ecr_repository" "main" {
  name = var.ecr_name

  image_scanning_configuration {
    scan_on_push = var.scan_on_push
  }
}

# Дозволяємо push і pull лише вказаному IAM principal
resource "aws_ecr_repository_policy" "main" {
  repository = aws_ecr_repository.main.name
  policy     = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Principal = {
          AWS = var.allowed_principal_arn
        }
        Action = [
          "ecr:BatchCheckLayerAvailability",
          "ecr:GetDownloadUrlForLayer",
          "ecr:BatchGetImage",
          "ecr:InitiateLayerUpload",
          "ecr:UploadLayerPart",
          "ecr:CompleteLayerUpload",
          "ecr:PutImage"
        ]
      }
    ]
  })
}
