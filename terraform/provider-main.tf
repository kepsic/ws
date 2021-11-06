# Configure the Microsoft Azure Provider
terraform {
  required_version = ">= 0.14"
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~>2.0"
    }
  }
}

#Configure the Azure Provider
#provider "azurerm" {
#  features {}
#  subscription_id = var.azure_subscription_id
#  client_id       = var.azure_client_id
#  client_secret   = var.azure_client_secret
#  tenant_id       = var.azure_tenant_id
#}

provider "azurerm" {
  features {}
}
