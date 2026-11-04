terraform {
  required_version = ">= 1.5.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

provider "aws" {
  region = var.aws_region
}

# ------------------------------------------------------------------
# Networking: VPC, subnets, IGW, route tables
# ------------------------------------------------------------------
module "networking" {
  source = "./modules/networking"

  project_name = var.project_name
}

# ------------------------------------------------------------------
# Security: EC2 and RDS security groups
# ------------------------------------------------------------------
module "security" {
  source = "./modules/security"

  project_name     = var.project_name
  vpc_id           = module.networking.vpc_id
  ssh_allowed_cidr = var.ssh_allowed_cidr
}

# ------------------------------------------------------------------
# Compute: Ubuntu EC2 in the public subnet
# ------------------------------------------------------------------
module "compute" {
  source = "./modules/compute"

  project_name          = var.project_name
  public_subnet_id      = module.networking.public_subnet_id
  ec2_security_group_id = module.security.ec2_security_group_id
  key_name              = var.key_name
  ssh_public_key        = file(var.ssh_public_key_path)
}

# ------------------------------------------------------------------
# Database: RDS MySQL in the private DB subnets
# ------------------------------------------------------------------
module "database" {
  source = "./modules/database"

  project_name          = var.project_name
  private_db_subnet_ids = module.networking.private_db_subnet_ids
  rds_security_group_id = module.security.rds_security_group_id
  db_username           = var.db_username
  db_password           = var.db_password
}
