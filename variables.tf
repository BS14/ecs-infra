locals {
  vpc_cidr = var.cidr
  common_tags = {
    Project     = var.project
    Environment = var.env
    Owner       = "Bnay14"
    ManagedBy   = "Terraform"
  }
}

variable "app_name" {
  type        = string
  description = "Name of Application"
  default     = "nextjs"
}

variable "cidr" {
  description = " VPC CIDR"
  default     = "10.0.0.0/16"
  type        = string
}

variable "project" {
  type        = string
  description = "Project Name."
  default     = "ecs"
}

variable "env" {
  type        = string
  description = "Name of Environment."
  default     = "prod"
}
