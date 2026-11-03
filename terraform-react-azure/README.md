# Terraform: Azure Linux VM running a React app

Provisions an Ubuntu 22.04 virtual machine on Azure and, on first boot, installs Node.js and Nginx, builds the [my-react-app](https://github.com/pravinmishraaws/my-react-app) project and serves it on port 80.

## What gets created

| Resource | Name |
|---|---|
| Resource group | `Terraform-Azure-VM-RG` (East US) |
| Virtual network | `Terraform-VNet` (`10.0.0.0/16`) |
| Subnet | `Terraform-Subnet` (`10.0.1.0/24`) |
| Public IP (Standard, static) | `Terraform-Public-IP` |
| Network interface | `Terraform-NIC` |
| Network security group | `Terraform-VM-NSG` (allows SSH on 22 and HTTP on 80) |
| Linux VM (`Standard_D2as_v4`, Ubuntu 22.04 LTS) | `Terraform-Azure-VM` |

The config outputs `public_ip_address` once the VM is created.

## Repository layout

```
terraform-react-azure/
├── main.tf                  # All resource definitions and the admin_password variable
├── setup-react.sh           # Cloud-init custom_data: installs Node.js and Nginx, builds and deploys the React app
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

A new or unused subscription may not have these providers registered. Without them, Terraform fails with `MissingSubscriptionRegistration` (HTTP 409).

| Provider | Used for |
|---|---|
| `Microsoft.Network` | VNet, subnet, public IP, NIC, NSG |
| `Microsoft.Compute` | Linux virtual machine |

```sh
az provider register -n Microsoft.Network --wait
az provider register -n Microsoft.Compute --wait
```

### 3. Set the VM admin password

The password is a **sensitive variable** with no default, so it is never written into the code. Set it in the shell you run Terraform from:

```sh
export TF_VAR_admin_password='<choose-a-strong-password>'
```

Azure Linux VM passwords must be 12 to 72 characters and contain at least three of: lowercase, uppercase, digits, special characters.

## Running the configuration

```sh
terraform init        # Download the azurerm provider (first time only)
terraform fmt -check  # Optional: check formatting
terraform validate    # Optional: check configuration syntax
terraform plan        # Preview the changes
terraform apply       # Create the resources (asks for confirmation)
```

After `apply`, the VM runs `setup-react.sh` on first boot. That takes a few minutes, because it runs `npm install` and `npm run build`. Then the app is available at:

```
http://<public_ip_address>
```

Get the IP with:

```sh
terraform output public_ip_address
```

### Connecting over SSH

```sh
ssh azureadmin@<public_ip_address>
```

To check whether the setup script has finished, look at its log on the VM:

```sh
sudo tail -f /var/log/cloud-init-output.log
```

### After recreating the VM

A recreated VM gets a new SSH host key, so SSH will refuse to connect with a `REMOTE HOST IDENTIFICATION HAS CHANGED` warning. Confirm the new fingerprint matches what Azure reports (boot diagnostics or the portal), then remove the stale entry:

```sh
ssh-keygen -R <public_ip_address>
```

`ssh-keygen -R` saves a backup at `~/.ssh/known_hosts.old`.

## Customising the app

`setup-react.sh` changes two lines in `src/App.js` before building (the "Deployed by" name and the date). Edit those `sed` lines in the script to match your details. Changes to `custom_data` only run on a new VM, so use `terraform apply` with a recreated VM to pick them up.

## Tearing down

To delete everything this configuration created, including the VM and its disk:

```sh
terraform destroy
```

VM and public IP costs accrue while they exist, so run this when you're finished.

## Security notes

- **Terraform state contains secrets.** `terraform.tfstate` stores the VM admin password in plain text. It is excluded by `.gitignore`. Never commit it or share it. For team use, store state in a private remote backend.
- **Never commit `.tfvars` files that hold values.** Commit only `*.tfvars.example` files with placeholders.
- **Rotate the password** if it was ever committed, pasted into chat, or shared. Change the value and run `terraform apply`.
- **The NSG opens SSH and HTTP to the whole internet.** Rules `Allow-SSH` (22) and `Allow-HTTP` (80) use source `*`. For anything beyond a training exercise, restrict SSH to your IP, or switch to SSH keys (`disable_password_authentication = true`).
- **The setup script runs as root on first boot** and pulls code from GitHub and a remote install script (`deb.nodesource.com`). Review those before using the config for anything real.
- **Do not paste subscription IDs, passwords or public IP addresses** into issues, pull requests or chat logs.

## Troubleshooting

| Error | Cause | Fix |
|---|---|---|
| `MissingSubscriptionRegistration ... 'Microsoft.Network'` | Network provider not registered | `az provider register -n Microsoft.Network --wait` |
| `MissingSubscriptionRegistration ... 'Microsoft.Compute'` | Compute provider not registered | `az provider register -n Microsoft.Compute --wait` |
| `SkuNotAvailable ... Capacity Restrictions` | VM size has no capacity in this region | Change `size` or `location` (check with `az vm list-skus -l <region> --resource-type virtualMachines`) |
| `No value for required variable "admin_password"` | `TF_VAR_admin_password` not set in this shell | Export it again (see setup step 3) |
| `Missing required provider` | `terraform init` not run | Run `terraform init` |
| `REMOTE HOST IDENTIFICATION HAS CHANGED` | VM was recreated and has a new host key | Run `ssh-keygen -R <public_ip_address>` (see above) |
| Page does not load after apply | Setup script still running, or it failed | Wait a few minutes, then check `/var/log/cloud-init-output.log` on the VM |
| Password rejected by Azure | Does not meet complexity rules | Use 12 to 72 characters with at least three character classes |
