provider "azurerm" {
  features {}
}

resource "azurerm_resource_group" "az_resourcegroup" {
  name     = "az_resourcegroup"
  location = var.location

  tags = {
    environment = "Terraform Demo"
  }
}