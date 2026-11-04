variable "project_name" {
  description = "Prefix used in resource names and the Project tag."
  type        = string
  default     = "epicbook"
}

variable "vpc_cidr" {
  description = "CIDR block for the VPC."
  type        = string
  default     = "10.0.0.0/16"
}

variable "availability_zones" {
  description = "Exactly two Availability Zones in the selected region. Index 0 hosts the public subnet and private DB subnet A; index 1 hosts private DB subnet B."
  type        = list(string)
  default     = ["us-east-1a", "us-east-1b"]

  validation {
    condition     = length(var.availability_zones) == 2
    error_message = "availability_zones must contain exactly two AZs (RDS needs subnets in at least two)."
  }
}

variable "public_subnet_cidr" {
  description = "CIDR for the public subnet that hosts the EC2 instance."
  type        = string
  default     = "10.0.1.0/24"
}

variable "private_db_subnet_a_cidr" {
  description = "CIDR for private database subnet A (AZ 1)."
  type        = string
  default     = "10.0.2.0/24"
}

variable "private_db_subnet_b_cidr" {
  description = "CIDR for private database subnet B (AZ 2)."
  type        = string
  default     = "10.0.3.0/24"
}

variable "tags" {
  description = "Additional tags applied to all network resources."
  type        = map(string)
  default     = {}
}
