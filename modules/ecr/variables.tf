variable "ecr_name" {
  description = "Назва ECR repository"
  type        = string
}

variable "scan_on_push" {
  description = "Вмикати сканування образів після push"
  type        = bool
}

variable "allowed_principal_arn" {
  description = "ARN IAM principal, якому repository policy дозволяє push і pull"
  type        = string
}
