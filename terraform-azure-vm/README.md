# Terraform: Azure Linux VM

Provisions a small Ubuntu 22.04 virtual machine on Azure, with its own resource group, virtual network, subnet, static public IP and network interface.

## What gets created

| Resource | Name |
|---|---|
| Resource group | `Terraform-Azure-VM-RG` (East US) |
| Virtual network | `Terraform-VNet` (`10.0.0.0/16`) |
| Subnet | `Terraform-Subnet` (`10.0.1.0/24`) |
| Public IP (Standard, static) | `Terraform-Public-IP` |
| Network interface | `Terraform-NIC` |
| Linux VM (`Standard_D2as_v4`, 2 vCPU / 8 GB, Ubuntu 22.04 LTS) | `Terraform-Azure-VM` |

The config outputs `public_ip_address` once the VM is created.

## Repository layout

```
terraform-azure-vm/
├── main.tf                  # All resource definitions and the admin_password variable
├── .terraform.lock.hcl      # Pinned provider versions (commit this)
├── .gitignore               # Keeps state, secrets and local cache out of git
└── README.md
```

## Prerequisites

- [Terraform](https://developer.hashicorp.com/terraform/install) (1.x)
- [Azure CLI](https://learn.microsoft.com/cli/azure/install-azure-cli)
- An Azure subscription where you have permission to create resources

## One-time setup

### 1. Sign in to Azure

```sh
az login
az account set --subscription "<your-subscription-id>"
az account show --query "{name:name, id:id}" -o table
```

Confirm the subscription shown is the one you intend to use.

### 2. Register the required resource providers

A new or unused subscription may not have these providers registered. Without them, Terraform fails with `MissingSubscriptionRegistration` (HTTP 409) when creating the network or VM resources.

| Provider | Used for |
|---|---|
| `Microsoft.Network` | VNet, subnet, public IP, NIC |
| `Microsoft.Compute` | Linux virtual machine |

```sh
az provider register -n Microsoft.Network --wait
az provider register -n Microsoft.Compute --wait
az provider show -n Microsoft.Network --query registrationState -o tsv
az provider show -n Microsoft.Compute --query registrationState -o tsv
```

Wait until both states are `Registered`.

### 3. Set the VM admin password

The password is a **sensitive variable** with no default, so it is never written into the code. Set it as an environment variable in the shell you run Terraform from:

```sh
export TF_VAR_admin_password='<choose-a-strong-password>'
```

Requirements for Azure Linux VM passwords: 12 to 72 characters, containing at least three of lowercase, uppercase, digits and special characters.

Do not put the password in `main.tf`, a `.tfvars` file that will be committed, or a commit message. Each shell session needs the variable set again, or you can store it in a password manager and paste it in.

## Running the configuration

```sh
terraform init        # Download the azurerm provider (first time only)
terraform fmt -check  # Optional: check formatting
terraform validate    # Optional: check configuration syntax
terraform plan        # Preview the changes
terraform apply       # Create the resources (asks for confirmation)
```

After `apply` finishes, get the public IP:

```sh
terraform output public_ip_address
```

Connect over SSH using the admin username `azureadmin` and the password you set:

```sh
ssh azureadmin@<public_ip_address>
```

## Tearing down

To delete everything this configuration created, including the VM and its disk:

```sh
terraform destroy
```

Run this when you're finished to avoid ongoing charges. VM and public IP costs accrue while they exist.

## Security notes

- **Terraform state contains secrets.** `terraform.tfstate` stores the VM admin password in plain text. It is excluded by `.gitignore`. Never commit it, and never share it. For team use, store state in a private remote backend (for example, an Azure Storage account with access controls) rather than locally.
- **Never commit `.tfvars` files that hold values.** `*.tfvars` is ignored. Commit only `*.tfvars.example` files that contain placeholders.
- **Rotate the password** if it was ever committed to git, pasted into chat, or shared. Changing the value and running `terraform apply` updates the VM.
- **SSH is open to the internet.** The NIC has no network security group, so port 22 is reachable from anywhere that can route to the public IP. For anything beyond a training exercise, add an NSG that restricts inbound SSH to your IP, or use SSH keys instead of passwords (set `disable_password_authentication = true` and provide a public key).
- **Do not paste subscription IDs, passwords or public IP addresses** into issues, pull requests or chat logs.

## Troubleshooting

| Error | Cause | Fix |
|---|---|---|
| `MissingSubscriptionRegistration ... 'Microsoft.Network'` | Network provider not registered | Run `az provider register -n Microsoft.Network --wait` (see setup step 2) |
| `MissingSubscriptionRegistration ... 'Microsoft.Compute'` | Compute provider not registered | Run `az provider register -n Microsoft.Compute --wait` (see setup step 2) |
| `SkuNotAvailable ... Capacity Restrictions` | The VM size has no capacity in this region for your subscription | Pick another size, or change `location` and the resource group location (check with `az vm list-skus -l <region> --resource-type virtualMachines`) |
| `No value for required variable "admin_password"` | `TF_VAR_admin_password` not set in this shell | Export it again (see setup step 3) |
| `Error: Failed to query available provider packages` or `Missing required provider` | `terraform init` not run | Run `terraform init` |
| `az: command not found` | Azure CLI not installed | Install the Azure CLI and run `az login` |
| Password rejected by Azure | Does not meet complexity rules | Use 12 to 72 characters with at least three character classes |
