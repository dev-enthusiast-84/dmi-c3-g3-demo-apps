variable "project_name" {
  description = "Prefix used in resource names and the Project tag."
  type        = string
  default     = "epicbook"
}

variable "private_db_subnet_ids" {
  description = "IDs of the two private database subnets from the networking module (module.networking.private_db_subnet_ids)."
  type        = list(string)

  validation {
    condition     = length(var.private_db_subnet_ids) >= 2
    error_message = "private_db_subnet_ids must contain at least two subnets in different AZs."
  }
}

variable "rds_security_group_id" {
  description = "ID of the RDS security group from the security module (module.security.rds_security_group_id)."
  type        = string
}

variable "engine_version" {
  description = "MySQL major/minor version for RDS."
  type        = string
  default     = "8.0"
}

variable "db_instance_class" {
  description = "RDS instance class. db.t3.micro is small and suitable for the lab."
  type        = string
  default     = "db.t3.micro"
}

variable "allocated_storage_gb" {
  description = "Allocated storage in GiB."
  type        = number
  default     = 20
}

variable "db_name" {
  description = "Name of the initial database created on the instance. Must match the database name the EpicBook app expects."
  type        = string
  default     = "bookstore"
}

variable "db_username" {
  description = "Database administrator username."
  type        = string
}

variable "db_password" {
  description = "Database administrator password. Supply via TF_VAR_db_password or a secret store; never commit it."
  type        = string
  sensitive   = true

  validation {
    condition     = length(var.db_password) >= 8
    error_message = "db_password must be at least 8 characters."
  }
}

variable "tags" {
  description = "Additional tags applied to database resources."
  type        = map(string)
  default     = {}
}
