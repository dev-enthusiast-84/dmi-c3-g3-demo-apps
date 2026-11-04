variable "project_name" {
  description = "Prefix used in resource names and the Project tag."
  type        = string
  default     = "epicbook"
}

variable "vpc_id" {
  description = "ID of the VPC the security groups are created in (module.networking.vpc_id)."
  type        = string
}

variable "ssh_allowed_cidr" {
  description = "CIDR allowed to SSH to the EC2 instance. Use your own public IP as a /32, e.g. \"203.0.113.10/32\"."
  type        = string

  validation {
    condition     = can(cidrhost(var.ssh_allowed_cidr, 0))
    error_message = "ssh_allowed_cidr must be a valid CIDR block, such as 203.0.113.10/32."
  }
}

variable "http_allowed_cidrs" {
  description = "CIDR blocks allowed to reach HTTP (port 80) on the EC2 instance."
  type        = list(string)
  default     = ["0.0.0.0/0"]
}

variable "tags" {
  description = "Additional tags applied to all security resources."
  type        = map(string)
  default     = {}
}
