module "naming" {
  source  = "Azure/naming/azurerm"
  version = "0.4.1"
  suffix  = ["${var.name}"]
}

resource "azurerm_resource_group" "resource_group" {
  name     = module.naming.resource_group.name
  location = var.location
}

resource "azurerm_virtual_network" "virtual_network" {
  name                = module.naming.virtual_network.name
  address_space       = ["10.0.0.0/16"]
  location            = azurerm_resource_group.resource_group.location
  resource_group_name = azurerm_resource_group.resource_group.name
}

resource "azurerm_subnet" "subnet" {
  name                 = join("-", [module.naming.subnet.name, "one"])
  resource_group_name  = azurerm_resource_group.resource_group.name
  virtual_network_name = azurerm_virtual_network.example.name
  address_prefixes     = ["10.0.2.0/24"]
}

resource "azurerm_public_ip" "public_ip" {
  name                = module.naming.public_ip.name
  resource_group_name = azurerm_resource_group.resource_group.name
  location            = azurerm_resource_group.resource_group.location
  allocation_method   = "Static"
}

resource "azurerm_network_interface" "network_interface" {
  name                = module.naming.network_interface.name
  location            = azurerm_resource_group.resource_group.location
  resource_group_name = azurerm_resource_group.resource_group.name

  ip_configuration {
    name                          = "internal"
    subnet_id                     = azurerm_subnet.subnet.id
    public_ip_address_id          = azurerm_public_ip.public_ip.id
    private_ip_address_allocation = "Dynamic"

  }
}

resource "azurerm_linux_virtual_machine" "linux_virtual_machine" {
  name                            = module.naming.virtual_machine.name
  resource_group_name             = azurerm_resource_group.resource_group.name
  location                        = azurerm_resource_group.resource_group.location
  size                            = "Standard_F2"
  admin_username                  = "adminuser"
  admin_password                  = var.admin_password
  disable_password_authentication = false
  network_interface_ids = [
    azurerm_network_interface.example.id,
  ]

  os_disk {
    caching              = "ReadWrite"
    storage_account_type = "Standard_LRS"
  }

  source_image_reference {
    publisher = "Canonical"
    offer     = "0001-com-ubuntu-server-jammy"
    sku       = "22_04-lts"
    version   = "latest"
  }

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