
resource "azurerm_storage_account" "this" {
  name = "stkfc${var.environment}${var.unique_suffix}"

  resource_group_name = var.resource_group_name
  location            = var.location

  account_tier             = "Standard"
  account_replication_type = "LRS"

  min_tls_version                 = "TLS1_2"
  allow_nested_items_to_be_public = false

  tags = {
    Project     = upper(var.project)
    Environment = upper(var.environment)
    ManagedBy   = "Terraform"
  }
}
