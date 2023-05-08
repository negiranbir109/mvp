terraform {
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 3.22.0"
    }
  }

  required_version = ">= 1.2.5"

  backend "azurerm" {}
}

provider "azurerm" {
  features {}
}

module "network" {
  source = "github.com/KPMG-UK/tf-azure-migrate-modules//modules/network"

  region                        = var.region
  create_new_resource_group     = true
  resource_group_name           = local.resource_group_name
  virtual_network_name          = local.virtual_network_name
  virtual_network_address_space = var.virtual_network_address_space
}