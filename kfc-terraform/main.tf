
terraform {
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 5.10.0"
    }
  }
}

provider "azurerm" {
  features {}
  subscription_id = var.subscription_id
}

# Resource group
resource "azurerm_resource_group" "kfc" {
  name     = "rg-${var.project}-${var.environment}-${var.region_code}-001"
  location = var.location

  tags = {
    Project     = upper(var.project)
    Environment = upper(var.environment)
    ManagedBy   = "Terraform"
  }
}

# Virtual network module
module "vnet" {
  source = "./modules/vnet"

  project                = var.project
  environment            = var.environment
  region_code            = var.region_code
  location               = var.location
  resource_group_name    = azurerm_resource_group.kfc.name
  address_space          = var.vnet_address_space
  subnet_address_prefixes = var.subnet_address_prefixes
}

# Storage account module
module "storage" {
  source = "./modules/storage"

  project             = var.project
  environment         = var.environment
  location            = var.location
  resource_group_name = azurerm_resource_group.kfc.name
  unique_suffix       = var.storage_unique_suffix
}

# Root outputs
output "resource_group_name" {
  value = azurerm_resource_group.kfc.name
}

output "vnet_name" {
  value = module.vnet.vnet_name
}

output "vnet_id" {
  value = module.vnet.vnet_id
}

output "subnet_id" {
  value = module.vnet.subnet_id
}

output "storage_account_name" {
  value = module.storage.storage_account_name
}

output "storage_account_id" {
  value = module.storage.storage_account_id
}
