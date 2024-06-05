module "naming" {
  source  = "Azure/naming/azurerm"
  version = "0.4.1"
  suffix  = ["${var.name}"]
}

resource "azurerm_resource_group" "resource_group" {
  name     = module.naming.resource_group.name
  location = var.location
}

module "avm-res-compute-virtualmachine" {
  source  = "Azure/avm-res-compute-virtualmachine/azurerm"
  version = "0.14.0"

  location                = var.location
  name                    = module.naming.virtual_machine.name
  resource_group_name     = azurerm_resource_group.resource_group.name
  virtualmachine_sku_size = "Standard_B2s"
  zone                    = 1

  custom_data = base64encode(
    <<-EOF
    #cloud-config
    package_upgrade: true
    runcmd:
      - test -d ~/.linuxbrew && eval "$(~/.linuxbrew/bin/brew shellenv)"
      - test -d /home/linuxbrew/.linuxbrew && eval "$(/home/linuxbrew/.linuxbrew/bin/brew shellenv)"
      - echo "eval \"\$($(brew --prefix)/bin/brew shellenv)\"" >> ~/.bashrc
      - brew install turbot/tap/powerpipe
      - brew install turbot/tap/steampipe
      - steampipe plugin install azure
      - steampipe plugin install azuread
      - mkdir powerpipe-dashboards
      - cd powerpipe-dashboards
      - powerpipe mod init
      - powerpipe mod install github.com/turbot/steampipe-mod-azure-insights
      - steampipe service start
      - powerpipe server
    EOF
  )
}