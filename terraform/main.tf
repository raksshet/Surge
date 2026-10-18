provider "azurerm" {
    features{}
}

resource "azurerm_resource_group" "example" {
    name     = "jatinbhalla"
    location = "eastus"
    tags     = {
        environment="dev"
    }
}