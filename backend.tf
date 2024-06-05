terraform {
  backend "azurerm" {
    resource_group_name  = "rg-storage-sandbox-uks"
    storage_account_name = "sacpcterraformbackend"
    container_name       = "terraform"
    key                  = "powerpipe_demo.tfstate"
    use_oidc             = true
  }
}

provider "azurerm" {
  features {}
}