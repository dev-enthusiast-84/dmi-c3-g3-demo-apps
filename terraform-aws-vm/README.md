# Terraform: AWS Linux VM

Provisions a small Ubuntu 22.04 EC2 instance in a new VPC in `us-east-1`, with a public subnet, internet access, an SSH/HTTP security group and an SSH key pair.

## What gets created

| Resource | Name |
|---|---|
| VPC (`10.0.0.0/16`, DNS enabled) | `Terraform-AWS-VPC` |
| Public subnet (`10.0.1.0/24`, auto-assigns public IP) | `Terraform-Public-Subnet` |
| Private subnet (`10.0.2.0/24`, no route out) | `Terraform-Private-Subnet` |
| Internet gateway | `Terraform-IGW` |
| Public route table (`0.0.0.0/0` to the IGW) | `Terraform-Public-RT` |
| Security group (SSH 22 and HTTP 80 open to `0.0.0.0/0`) | `Terraform-Web-SG` |
| Key pair (from your local public key) | `terraform-aws-vm-key` |
| EC2 instance (`t3.micro`, latest Ubuntu 22.04 LTS AMI from Canonical) | `Terraform-AWS-VM` |

The config outputs `public_ip_address` once the instance is created.

The private subnet is created but nothing is attached to it, so it has no route to the internet.

## Repository layout

```
terraform-aws-vm/
├── main.tf                  # All resource definitions and the output
├── .terraform.lock.hcl      # Pinned provider versions (commit this)
├── .gitignore               # Keeps state, secrets and local cache out of git
└── README.md
```

## Prerequisites

- [Terraform](https://developer.hashicorp.com/terraform/install) (1.x)
- [AWS CLI](https://docs.aws.amazon.com/cli/latest/userguide/getting-started-install.html)
- An AWS account or IAM user with permission to create VPC, EC2 and key pair resources
- An SSH key pair at `~/.ssh/terraform-aws-vm-key.pub` (see setup step 2)

## One-time setup

### 1. Configure AWS credentials

Use a named profile backed by an IAM user (access keys or SSO). Avoid the root account.

```sh
aws configure --profile dmi-c3-g3-training   # or run `aws sso login --profile <name>`
aws sts get-caller-identity --profile dmi-c3-g3-training
```

Confirm the ARN is the IAM user you expect, not `:root`.

Terraform does not read the `aws login` root session that is sometimes set as `default`. If you see `No valid credential sources found` or `no EC2 IMDS role found`, Terraform has no usable credentials. Select a profile explicitly (step 3).

### 2. Create the SSH key

The key pair resource reads the public key from a hard-coded path in `main.tf`:

```sh
ssh-keygen -t ed25519 -f ~/.ssh/terraform-aws-vm-key -C "terraform-aws-vm"
```

Keep the private key (`terraform-aws-vm-key`) private. Only the `.pub` file is referenced by the config.

### 3. Select the AWS profile

Either export it in each shell:

```sh
export AWS_PROFILE=dmi-c3-g3-training
```

or add it to the provider block in `main.tf`:

```hcl
provider "aws" {
  region  = "us-east-1"
  profile = "dmi-c3-g3-training"
}
```

## Running the configuration

```sh
terraform init        # Download the aws provider (first time only)
terraform fmt -check  # Optional: check formatting
terraform validate    # Optional: check configuration syntax
terraform plan        # Preview the changes
terraform apply       # Create the resources (asks for confirmation)
```

After `apply` finishes, get the public IP:

```sh
terraform output public_ip_address
```

Connect over SSH. The default user on the Ubuntu AMI is `ubuntu`:

```sh
ssh -i ~/.ssh/terraform-aws-vm-key ubuntu@<public_ip_address>
```

## Tearing down

To delete everything this configuration created:

```sh
terraform destroy
```

Run this when you're finished to avoid ongoing charges. The EC2 instance accrues cost while it is running.

## Security notes

- **Terraform state contains sensitive data.** `terraform.tfstate` can include resource details and IDs. It is excluded by `.gitignore`. Never commit it. For team use, store state in a private remote backend (for example, S3 with DynamoDB locking) instead of locally.
- **Never commit `.tfvars` files that hold values.** `*.tfvars` is ignored. Commit only `*.tfvars.example` files that contain placeholders.
- **SSH and HTTP are open to the whole internet.** `Terraform-Web-SG` allows port 22 and port 80 from `0.0.0.0/0`. For anything beyond a training exercise, restrict SSH `cidr_blocks` to your own IP (for example `["203.0.113.10/32"]`).
- **Do not use the root account for Terraform.** Use a scoped IAM user or role.
- **Do not paste account IDs, key material or public IP addresses** into issues, pull requests or chat logs.

## Troubleshooting

| Error | Cause | Fix |
|---|---|---|
| `No valid credential sources found` | No profile selected, or the profile has no usable keys | Set `AWS_PROFILE` or the provider `profile` (setup step 3) |
| `no EC2 IMDS role found ... 169.254.169.254` | Same as above: Terraform fell back to the instance metadata service | Same as above |
| `NoCredentials: Unable to locate credentials` | The profile is configured but not logged in or has no keys | Run `aws configure --profile <name>` or `aws sso login --profile <name>` |
| `Error reading file ... terraform-aws-vm-key.pub` | SSH public key missing at the hard-coded path | Create it (setup step 2) or change the path in `main.tf` |
| `UnauthorizedOperation` or `AccessDenied` | The IAM identity cannot create VPC, EC2 or key pair resources | Use an identity with those permissions |
| `Error: Failed to query available provider packages` or `Missing required provider` | `terraform init` not run | Run `terraform init` |
| `aws: command not found` | AWS CLI not installed | Install the AWS CLI |
| `Permission denied (publickey)` on SSH | Wrong key or user | Use `-i ~/.ssh/terraform-aws-vm-key` and user `ubuntu` |
