terraform {
  backend "azurerm" {
  }
}

provider "azurerm" {
  use_oidc = true
  features {}
}