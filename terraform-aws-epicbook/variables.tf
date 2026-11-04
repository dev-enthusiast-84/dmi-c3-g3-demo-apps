variable "aws_region" {
  description = "AWS region to deploy into."
  type        = string
  default     = "us-east-1"
}

variable "project_name" {
  description = "Prefix used in resource names and tags."
  type        = string
  default     = "epicbook"
}

variable "key_name" {
  description = "Name for the EC2 key pair Terraform creates in the selected region."
  type        = string
  default     = "epicbook-aws-key"
}

variable "ssh_public_key_path" {
  description = "Absolute path to your SSH public key file (e.g. /Users/you/.ssh/epicbook-aws-key.pub). Terraform cannot expand ~."
  type        = string
}

variable "ssh_allowed_cidr" {
  description = "Your public IP as a /32 (e.g. \"203.0.113.10/32\"). Only this address can SSH to the instance."
  type        = string
}

variable "db_username" {
  description = "RDS MySQL administrator username."
  type        = string
}

variable "db_password" {
  description = "RDS MySQL administrator password. Supply with TF_VAR_db_password; do not store it in terraform.tfvars."
  type        = string
  sensitive   = true
}
