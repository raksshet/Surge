
resource "azurerm_virtual_network" "this" {
  name                = "vnet-${var.project}-${var.environment}-${var.region_code}-001"
  location            = var.location
  resource_group_name = var.resource_group_name
  address_space       = var.address_space

  tags = {
    Project     = upper(var.project)
    Environment = upper(var.environment)
    ManagedBy   = "Terraform"
  }
}

resource "azurerm_subnet" "this" {
  name                 = "snet-${var.project}-${var.environment}-001"
  resource_group_name  = var.resource_group_name
  virtual_network_name = azurerm_virtual_network.this.name
  address_prefixes     = var.subnet_address_prefixes
}
