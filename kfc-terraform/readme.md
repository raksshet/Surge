# KFC Azure Infrastructure — Terraform Learning Notes

## 1. Learning Objective

Build Azure infrastructure for the KFC project using Terraform, starting with DEV and extending to QA and HOM later.

### Planned infrastructure

- Azure Resource Group
- Virtual Network (VNet) and Subnet
- Storage Account
- Azure Container Registry (ACR)
- Azure Kubernetes Service (AKS)
- Two Linux Virtual Machines for Jenkins

### Terraform concepts to practise

- Variables and `.tfvars` files
- Terraform data types
- Modules and reusable infrastructure
- `for_each` for multiple resources
- Data blocks
- Import blocks
- Outputs and passing values between modules
- Terraform state management

---

## 2. Terraform Project Structure

```text
KFC-Terraform/
├── main.tf
├── variable.tf
├── dev.tfvars
├── qa.tfvars
└── modules/
    ├── vnet/
    │   ├── main.tf
    │   ├── variable.tf
    │   └── outputs.tf
    ├── storage/
    │   ├── main.tf
    │   ├── variable.tf
    │   └── outputs.tf
    ├── acr/
    │   ├── main.tf
    │   ├── variable.tf
    │   └── outputs.tf
    ├── linux-vm/
    │   ├── main.tf
    │   ├── variable.tf
    │   └── outputs.tf
    └── aks/
        ├── main.tf
        ├── variable.tf
        └── outputs.tf
```

### File responsibilities

| File | Purpose |
|---|---|
| Root `main.tf` | Defines root resources and calls modules |
| Root `variable.tf` | Declares inputs for the root configuration |
| `dev.tfvars` | Provides values for DEV |
| `qa.tfvars` | Provides values for QA |
| Module `main.tf` | Defines resources managed by that module |
| Module `variable.tf` | Declares inputs accepted by the module |
| Module `outputs.tf` | Exposes values from the module |

Terraform loads all `.tf` files in the same directory as one module. A child module's directory has its own scope.

---

## 3. Variables and Environment Configuration

Variables allow infrastructure configuration to be separated from environment-specific values.

Example root variable:

```hcl
variable "environment" {
  description = "Deployment environment"
  type        = string
}
```

Example `dev.tfvars`:

```hcl
project     = "kfc"
environment = "dev"
location    = "centralindia"
region_code = "ci"
```

Example `qa.tfvars`:

```hcl
project     = "kfc"
environment = "qa"
location    = "centralindia"
region_code = "ci"
```

Deploy using the appropriate variable file:

```powershell
terraform plan -var-file="dev.tfvars"
terraform apply -var-file="dev.tfvars"

terraform plan -var-file="qa.tfvars"
terraform apply -var-file="qa.tfvars"
```

**Important:** Different `.tfvars` files do not automatically isolate Terraform state. DEV and QA should use separate state files or separate backend keys.

### Terraform data types covered

| Type | Example | Use |
|---|---|---|
| `string` | `"dev"` | Environment, project, region |
| `number` | `2` | VM count or numeric settings |
| `bool` | `true` | Enable/disable settings |
| `list(string)` | `["10.10.0.0/16"]` | Network address ranges |
| `map(string)` | `{ env = "dev" }` | Key-value configuration |
| `object` | Structured VM settings | Different properties per VM |

---

## 4. Terraform Naming Convention

KFC resources use consistent project, environment, region, and resource abbreviations.

| Resource | Naming pattern | DEV example |
|---|---|---|
| Resource Group | `rg-project-env-region-001` | `rg-kfc-dev-ci-001` |
| Storage Account | `st` + project + env + unique suffix | `stkfcdeva1b2c3` |
| Virtual Network | `vnet-project-env-region-001` | `vnet-kfc-dev-ci-001` |
| Subnet | `snet-project-env-001` | `snet-kfc-dev-001` |
| Linux VM | `vm-project-env-role-001` | `vm-kfc-dev-jenkins-001` |
| Network Interface | `nic-project-env-role-001` | `nic-kfc-dev-jenkins-001` |

Storage account names must be globally unique, contain only lowercase letters and numbers, and be 3–24 characters long.

---

## 5. What Is a Terraform Module?

A module is a collection of Terraform configuration that packages related infrastructure into a reusable component.

Example modules:

- `vnet` — creates a virtual network and subnet.
- `storage` — creates a storage account.
- `acr` — creates an Azure Container Registry.
- `linux-vm` — creates Linux VMs.
- `aks` — creates a Kubernetes cluster.

### Why modules are useful

Without modules, resource definitions can accumulate in the root configuration.

With modules, the root configuration calls reusable components and passes the required inputs.

```hcl
module "vnet" {
  source = "./modules/vnet"

  project                 = var.project
  environment             = var.environment
  region_code             = var.region_code
  location                = var.location
  resource_group_name     = azurerm_resource_group.kfc.name
  address_space           = var.vnet_address_space
  subnet_address_prefixes = var.subnet_address_prefixes
}
```

The module can be reused in DEV, QA, HOM, or another project by supplying different inputs.

Modules are particularly useful when the same infrastructure design must be maintained and reused across multiple projects.

---

## 6. Root Variables vs. Module Variables

The same variable name can exist in the root and in a child module because each module has its own scope.

Example:

Root `variable.tf`:

```hcl
variable "environment" {
  type = string
}
```

Child `modules/vnet/variable.tf`:

```hcl
variable "environment" {
  type = string
}
```

These declarations are independent.

The root configuration explicitly passes the value:

```hcl
module "vnet" {
  source = "./modules/vnet"

  environment = var.environment
}
```

The child module receives it through its own `var.environment`.

Declaring the same variable twice in the same module, however, causes a duplicate declaration error.

---

## 7. What Is `outputs.tf`?

Outputs expose useful values from resources or modules.

Example `modules/vnet/outputs.tf`:

```hcl
output "vnet_id" {
  description = "Virtual network ID"
  value       = azurerm_virtual_network.this.id
}

output "subnet_id" {
  description = "Subnet ID"
  value       = azurerm_subnet.this.id
}
```

Outputs work with or without modules. A root-level output can expose a resource name, ID, or IP address.

Retrieve outputs after deployment:

```powershell
terraform output
terraform output subnet_id
```

For a scalar string:

```powershell
terraform output -raw storage_account_id
```

`outputs.tf` is a naming convention, not a mandatory filename. Output blocks can be declared in any `.tf` file in the same module.

---

## 8. Passing Outputs Between Modules

The root configuration connects the output of one module to the input variable of another.

### Step 1: VNet module creates a subnet

```hcl
resource "azurerm_subnet" "this" {
  name                 = "snet-kfc-dev-001"
  resource_group_name  = var.resource_group_name
  virtual_network_name = azurerm_virtual_network.this.name
  address_prefixes     = var.subnet_address_prefixes
}
```

### Step 2: VNet module exposes its subnet ID

```hcl
output "subnet_id" {
  value = azurerm_subnet.this.id
}
```

### Step 3: Jenkins module declares an input

```hcl
variable "subnet_id" {
  description = "Subnet ID for Jenkins networking"
  type        = string
}
```

### Step 4: Root configuration passes the output

```hcl
module "jenkins_vm" {
  source = "./modules/linux-vm"

  subnet_id = module.vnet.subnet_id
}
```

### Step 5: Jenkins module uses the input

```hcl
resource "azurerm_network_interface" "this" {
  # Other NIC properties omitted

  ip_configuration {
    name                          = "internal"
    subnet_id                     = var.subnet_id
    private_ip_address_allocation = "Dynamic"
  }
}
```

**Remember:**

- `output` exposes a value.
- `variable` receives a value.
- The root module connects the two.
- Terraform infers dependencies from resource references.

The same pattern can connect the VNet to AKS and the ACR module to deployment configurations.

---

## 9. SSH Key Authentication for Linux VMs

An SSH key pair contains two files.

| File | Purpose |
|---|---|
| `kfc-azure` | Private key; keep secret |
| `kfc-azure.pub` | Public key; supplied to Azure |

The `.pub` extension might be associated with Microsoft Publisher by Windows, but the file can still contain a valid SSH public key.

Generate an Ed25519 key pair:

```powershell
ssh-keygen -t ed25519 -f "$HOME\.ssh\kfc-azure"
```

Display the public key:

```powershell
Get-Content "$HOME\.ssh\kfc-azure.pub"
```

Copy the entire public-key line into the Terraform variable:

```hcl
ssh_public_key = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAA... comment"
```

The SHA256 fingerprint is an identifier for the key, not the public key itself.

Connect to a deployed VM:

```powershell
ssh -i "$HOME\.ssh\kfc-azure" azureadmin@YOUR-VM-PUBLIC-IP
```

Never commit the private key to Git or place it in a public repository.

---

## 10. CIDR and Network Security

An IPv4 address contains 32 bits, represented as four 8-bit octets.

Example:

```text
49.205.10.25
```

The `/32` CIDR suffix means all 32 bits are fixed, matching exactly one IPv4 address.

For SSH access in an Azure Network Security Group:

```hcl
admin_source_ip_cidr = "YOUR_PUBLIC_IP/32"
```

Examples:

| CIDR | Meaning |
|---|---|
| `49.205.10.25/32` | One IPv4 address |
| `10.10.1.0/24` | 256 addresses |
| `0.0.0.0/0` | All IPv4 addresses |

Use your actual public IP with `/32` for personal SSH access. Update the value if your public IP changes.

---

## 11. `data` and `import` Blocks

These are upcoming learning topics.

### Data blocks

A `data` block reads information about an existing resource without creating or managing that resource directly.

Typical uses:

- Retrieve an existing VNet.
- Read an existing subnet ID.
- Retrieve an existing resource group.
- Reuse an existing image or other Azure configuration.

Example:

```hcl
data "azurerm_resource_group" "existing" {
  name = "rg-kfc-dev-ci-001"
}
```

This looks up the resource group; it does not create it.

### Import blocks

An `import` block brings an existing Azure resource into Terraform state so Terraform can manage it.

It is useful when a resource was created manually or by another process and needs to be adopted into Terraform management.

Do not import a resource that is already tracked in the current state. Use `data` when you only need to read a resource managed elsewhere.

---

## 12. `for_each` for Two Jenkins VMs

Instead of writing two separate Linux VM resource blocks, use a map and `for_each`.

Example configuration:

```hcl
jenkins_vms = {
  jenkins01 = {
    vm_size = "Standard_B2s"
  }
  jenkins02 = {
    vm_size = "Standard_B2s"
  }
}
```

The VM module can use `for_each` to create one instance for each map entry.

This avoids duplicate resource definitions and makes it easier to add another Jenkins VM later by adding a new map entry.

`for_each` can be used without modules; the two concepts solve different problems.

---

## 13. Terraform Commands Reference

Run commands from the Terraform root directory.

```powershell
# Authenticate with Azure
az login

# Verify subscription
az account show

# Initialize providers and modules
terraform init

# Format Terraform files
terraform fmt -recursive

# Validate syntax and configuration
terraform validate

# Review planned changes
terraform plan -var-file="dev.tfvars"

# Save a plan for review
terraform plan -var-file="dev.tfvars" -out="dev.tfplan"

# Apply the reviewed plan
terraform apply "dev.tfplan"

# List resources in state
terraform state list

# View outputs
terraform output
```

A plan file can contain sensitive information. Keep it out of public Git repositories.

### State management reminder

Terraform state records the resources managed by a particular configuration. Destroying Azure resources does not always mean all state entries have disappeared.

For multiple environments, use separate state files or separate backend keys and keep backups secure.

---

## 14. Current Project Status

### Completed learning

- Created and destroyed Azure resources with Terraform.
- Used root variables and environment-specific `.tfvars` files.
- Understood Azure naming conventions.
- Generated an SSH key pair and configured public-key authentication.
- Learned CIDR notation and `/32`.
- Understood root and module variable scopes.
- Learned the purpose of modules and their reuse across projects.
- Understood outputs and passing values between modules.
- Discussed the role of `data` and `import` blocks.

### Planned implementation

1. Build KFC DEV foundation: resource group, VNet, subnet, and storage account.
2. Create the ACR module.
3. Create two Jenkins Linux VMs using `for_each`.
4. Create the AKS module.
5. Validate outputs and state management.
6. Add QA using the same reusable modules.
7. Extend to HOM with minimal configuration changes.

### Important implementation note

The design and examples in these notes describe the intended architecture and learning patterns. Verify that the actual Terraform files validate and deploy successfully before treating any component as implemented.

---

## 15. Reference Links

- [Terraform Language Documentation](https://developer.hashicorp.com/terraform/language)
- [Terraform Modules](https://developer.hashicorp.com/terraform/language/modules)
- [Terraform Input Variables](https://developer.hashicorp.com/terraform/language/values/variables)
- [Terraform Outputs](https://developer.hashicorp.com/terraform/language/values/outputs)
- [Terraform Data Sources](https://developer.hashicorp.com/terraform/language/data-sources)
- [Terraform Import](https://developer.hashicorp.com/terraform/language/import)
- [Terraform `for_each`](https://developer.hashicorp.com/terraform/language/meta-arguments/for_each)
- [Azure Provider Documentation](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs)
- [Azure Resource Naming Guidance](https://learn.microsoft.com/en-us/azure/architecture/best-practices/resource-naming)
