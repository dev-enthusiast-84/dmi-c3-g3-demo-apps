# ------------------------------------------------------------------
# Latest Ubuntu LTS AMI (Canonical), looked up by name so the AMI ID
# is never hard-coded and stays valid for the selected region.
# ------------------------------------------------------------------
data "aws_ami" "ubuntu" {
  most_recent = true
  owners      = [var.ami_owner]

  filter {
    name   = "name"
    values = [var.ami_name_filter]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }

  filter {
    name   = "architecture"
    values = ["x86_64"]
  }
}

# ------------------------------------------------------------------
# SSH key pair: registers your local public key with AWS
# ------------------------------------------------------------------
resource "aws_key_pair" "app" {
  key_name   = var.key_name
  public_key = var.ssh_public_key

  tags = merge(
    {
      Name      = var.key_name
      Project   = var.project_name
      ManagedBy = "terraform"
    },
    var.tags
  )
}

# ------------------------------------------------------------------
# EC2 instance: public subnet, security-module security group,
# public IPv4, and EpicBook prerequisites installed via user_data.
# ------------------------------------------------------------------
resource "aws_instance" "app" {
  ami                         = data.aws_ami.ubuntu.id
  instance_type               = var.instance_type
  subnet_id                   = var.public_subnet_id
  vpc_security_group_ids      = [var.ec2_security_group_id]
  key_name                    = aws_key_pair.app.key_name
  associate_public_ip_address = true

  user_data = file("${path.module}/user_data.sh")

  # Re-run user_data on the next apply if the script changes.
  user_data_replace_on_change = true

  root_block_device {
    volume_size = var.root_volume_size_gb
    volume_type = "gp3"
  }

  tags = merge(
    {
      Name      = "${var.project_name}-app"
      Project   = var.project_name
      ManagedBy = "terraform"
    },
    var.tags
  )
}
