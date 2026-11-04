# EpicBook on AWS with Terraform

Terraform configuration that provisions the AWS infrastructure for the EpicBook app:

- A VPC with public and private subnets (networking module)
- Security groups for the EC2 app server and the RDS database (security module)
- An Ubuntu 22.04 LTS EC2 instance in the public subnet, with an SSH key pair and prerequisites installed via `user_data` (compute module)
- A private MySQL 8.0 RDS instance in the database subnets (database module)

## Architecture

```
Internet ──SSH (ssh_allowed_cidr only)──► EC2 (public subnet)  ──► RDS MySQL (private DB subnets)
Internet ──HTTP :80──────────────────────► EC2 (nginx → 127.0.0.1:8080)
```

- The RDS instance is not publicly accessible. Only the EC2 security group can reach it on port 3306.
- SSH is limited to the single CIDR in `ssh_allowed_cidr`.

## Layout

```
.
├── main.tf              # Wires the modules together and configures the AWS provider
├── variables.tf         # Input variables
├── outputs.tf           # ec2_public_ip, rds_endpoint
├── terraform.tfvars     # Your environment values (git-ignored)
├── nginx.config         # Reverse-proxy config: port 80 → app on 127.0.0.1:8080
└── modules/
    ├── networking/      # VPC, subnets, internet gateway, route tables
    ├── security/        # EC2 and RDS security groups
    ├── compute/         # Ubuntu AMI lookup, key pair, EC2 instance, user_data.sh
    └── database/        # DB subnet group and RDS MySQL instance
```

## Prerequisites

- Terraform `>= 1.5.0`
- AWS CLI, with a profile that can create VPC, EC2, and RDS resources
- An SSH key pair on your machine, e.g. `~/.ssh/epicbook-aws-key` and `~/.ssh/epicbook-aws-key.pub`

## Configuration

1. Edit `terraform.tfvars` with your values:

   ```hcl
   aws_region          = "us-east-1"
   project_name        = "epicbook"
   key_name            = "epicbook-aws-key"
   ssh_public_key_path = "/Users/you/.ssh/epicbook-aws-key.pub"  # absolute path, no ~
   ssh_allowed_cidr    = "203.0.113.10/32"                         # your public IP
   db_username         = "epicbook_admin"
   ```

2. Pass secrets through the environment. Do not put them in `terraform.tfvars`:

   ```bash
   export AWS_PROFILE=<your-profile>
   export TF_VAR_db_password='<at least 8 characters>'
   ```

## Usage

```bash
terraform init
terraform plan
terraform apply
```

When apply finishes, the outputs show the EC2 public IP and the RDS endpoint:

```bash
terraform output ec2_public_ip
terraform output rds_endpoint
```

Connect to the instance:

```bash
ssh -i ~/.ssh/epicbook-aws-key ubuntu@<ec2_public_ip>
```

RDS takes several minutes to create (typically 5–15). Terraform waits for it before finishing.

To tear everything down:

```bash
terraform destroy
```

`skip_final_snapshot = true` and `deletion_protection = false` are set for lab use, so destroy completes without a snapshot. Do not use these settings for production.

## Notes and troubleshooting

| Symptom | Cause | Fix |
|---|---|---|
| `No valid credential sources found` / EC2 IMDS error | No AWS credentials in the shell | `export AWS_PROFILE=<profile>` (or configure credentials) before running Terraform |
| `Your query returned no results` on `data "aws_ami" "ubuntu"` | The AMI name filter doesn't match a published image | Check the pattern with `aws ec2 describe-images --owners 099720109477`. The default is `ubuntu/images/hvm-ssd/ubuntu-jammy-22.04-amd64-server-*` |
| `No value for required variable "db_password"` | `TF_VAR_db_password` not set | Export it in the same shell |
| SSH hangs or times out | Your public IP changed, so it no longer matches `ssh_allowed_cidr` | Update the CIDR and re-apply |
| `Permissions 0644 are too open` on the key | The private key file is readable by others | `chmod 400 ~/.ssh/epicbook-aws-key` |

## Post-provisioning

`user_data.sh` installs Node.js (LTS), npm, git, nginx, and the MySQL client, and enables nginx. It does **not** deploy the EpicBook application or copy `nginx.config` to the server. Do those steps manually after SSH, or add them to `user_data.sh`:

1. Clone the app and start it on port 8080.
2. Copy `nginx.config` to `/etc/nginx/sites-available/default` and reload nginx.
3. Point the app's database settings at the `rds_endpoint` output, using `db_username` and `TF_VAR_db_password`.

## Security

- Never commit `terraform.tfvars`, `*.tfstate`, or `*.pem`. They are listed in `.gitignore`.
- The state file contains the database password in plain text. Store it securely, or move to a remote backend with encryption.
