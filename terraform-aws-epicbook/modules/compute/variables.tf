variable "project_name" {
  description = "Prefix used for the instance Name tag."
  type        = string
  default     = "epicbook"
}

variable "public_subnet_id" {
  description = "ID of the public subnet from the networking module (module.networking.public_subnet_id)."
  type        = string
}

variable "ec2_security_group_id" {
  description = "ID of the EC2 security group from the security module (module.security.ec2_security_group_id)."
  type        = string
}

variable "key_name" {
  description = "Name of the EC2 key pair Terraform creates for SSH access."
  type        = string
  default     = "epicbook-aws-key"
}

variable "ssh_public_key" {
  description = "Contents of the SSH public key to register as the EC2 key pair (e.g. file(\"~/.ssh/epicbook-aws-key.pub\") from the root module)."
  type        = string
}

variable "instance_type" {
  description = "EC2 instance type."
  type        = string
  default     = "t3.micro"
}

variable "ami_owner" {
  description = "AWS account that owns the Ubuntu AMI. 099720109477 is Canonical."
  type        = string
  default     = "099720109477"
}

variable "ami_name_filter" {
  description = "Name pattern for the Ubuntu LTS AMI. Default is Ubuntu 22.04 LTS (Jammy), amd64, gp3 root."
  type        = string
  default     = "ubuntu/images/hvm-ssd/ubuntu-jammy-22.04-amd64-server-*"
}

variable "root_volume_size_gb" {
  description = "Root EBS volume size in GiB."
  type        = number
  default     = 20
}

variable "tags" {
  description = "Additional tags applied to the instance."
  type        = map(string)
  default     = {}
}
