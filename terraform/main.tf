
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

# 1. Resource Group
resource "azurerm_resource_group" "kfc_rg" {
  name     = "rg-${var.project}-${var.environment}-${var.region_code}-001"
  location = var.location

  tags = {
    Project     = "KFC"
    Environment = upper(var.environment)
    ManagedBy   = "Terraform"
  }
}

# 2. Storage Account
resource "azurerm_storage_account" "kfc_storage" {
  name = "stkfc${var.environment}${var.unique_suffix}"

  resource_group_name = azurerm_resource_group.kfc_rg.name
  location            = azurerm_resource_group.kfc_rg.location

  account_tier             = "Standard"
  account_replication_type = "LRS"

  min_tls_version                 = "TLS1_2"
  allow_nested_items_to_be_public = false

  tags = {
    Project     = "KFC"
    Environment = upper(var.environment)
    ManagedBy   = "Terraform"
  }
}

# 3. Virtual Network
resource "azurerm_virtual_network" "kfc_vnet" {
  name                = "vnet-${var.project}-${var.environment}-${var.region_code}-001"
  address_space       = var.vnet_address_space
  location            = azurerm_resource_group.kfc_rg.location
  resource_group_name = azurerm_resource_group.kfc_rg.name

  tags = {
    Project     = "KFC"
    Environment = upper(var.environment)
    ManagedBy   = "Terraform"
  }
}

# Supporting resource: Subnet
resource "azurerm_subnet" "kfc_subnet" {
  name                 = "snet-${var.project}-${var.environment}-vm-001"
  resource_group_name  = azurerm_resource_group.kfc_rg.name
  virtual_network_name = azurerm_virtual_network.kfc_vnet.name
  address_prefixes     = var.subnet_address_prefix
}

# Supporting resource: Network Security Group
resource "azurerm_network_security_group" "kfc_nsg" {
  name                = "nsg-${var.project}-${var.environment}-vm-001"
  location            = azurerm_resource_group.kfc_rg.location
  resource_group_name = azurerm_resource_group.kfc_rg.name

  security_rule {
    name                       = "Allow-SSH-From-My-IP"
    priority                   = 100
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "22"
    source_address_prefix      = var.admin_source_ip_cidr
    destination_address_prefix = "*"
  }
}

# Supporting resource: Public IP
resource "azurerm_public_ip" "kfc_public_ip" {
  name                = "pip-${var.project}-${var.environment}-vm-001"
  location            = azurerm_resource_group.kfc_rg.location
  resource_group_name = azurerm_resource_group.kfc_rg.name
  allocation_method   = "Static"
  sku                 = "Standard"
}

# Supporting resource: Network Interface
resource "azurerm_network_interface" "kfc_nic" {
  name                = "nic-${var.project}-${var.environment}-vm-001"
  location            = azurerm_resource_group.kfc_rg.location
  resource_group_name = azurerm_resource_group.kfc_rg.name

  ip_configuration {
    name                          = "internal"
    subnet_id                     = azurerm_subnet.kfc_subnet.id
    private_ip_address_allocation = "Dynamic"
    public_ip_address_id          = azurerm_public_ip.kfc_public_ip.id
  }
}

resource "azurerm_network_interface_security_group_association" "kfc_nic_nsg" {
  network_interface_id      = azurerm_network_interface.kfc_nic.id
  network_security_group_id = azurerm_network_security_group.kfc_nsg.id
}

# 4. Linux (Unix) Virtual Machine
resource "azurerm_linux_virtual_machine" "kfc_vm" {
  name                = "vm-${var.project}-${var.environment}-unx-001"
  computer_name       = "kfc-${var.environment}-unx-001"
  resource_group_name = azurerm_resource_group.kfc_rg.name
  location            = azurerm_resource_group.kfc_rg.location
  size                = var.vm_size

  admin_username                  = var.admin_username
  disable_password_authentication = true

  network_interface_ids = [
    azurerm_network_interface.kfc_nic.id
  ]

  admin_ssh_key {
    username   = var.admin_username
    public_key = var.ssh_public_key
  }

  os_disk {
    caching              = "ReadWrite"
    storage_account_type = "Standard_LRS"
  }

  source_image_reference {
    publisher = "Canonical"
    offer     = "0001-com-ubuntu-server-jammy"
    sku       = "22_04-lts-gen2"
    version   = "latest"
  }

  tags = {
    Project     = "KFC"
    Environment = upper(var.environment)
    ManagedBy   = "Terraform"
  }
}

# Useful results without a separate outputs.tf
output "resource_group_name" {
  value = azurerm_resource_group.kfc_rg.name
}

output "storage_account_name" {
  value = azurerm_storage_account.kfc_storage.name
}

output "vnet_name" {
  value = azurerm_virtual_network.kfc_vnet.name
}

output "vm_name" {
  value = azurerm_linux_virtual_machine.kfc_vm.name
}

output "vm_public_ip" {
  value = azurerm_public_ip.kfc_public_ip.ip_address
}
