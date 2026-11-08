output "repository_url" {
  description = "URL ECR repository для Docker images"
  value       = aws_ecr_repository.main.repository_url
}
