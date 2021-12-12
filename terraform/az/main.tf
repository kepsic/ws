# Create a resource group if it doesn't exist
resource "azurerm_resource_group" "emon_tf_group" {
  name     = var.resource_group_name
  location = var.az_location

  tags = {
    environment = "Terraform Emon"
  }
}

# Create virtual network
resource "azurerm_virtual_network" "emon_tf_network" {
  name                = "emonVnet"
  address_space       = ["10.0.0.0/16"]
  location            = var.az_location
  resource_group_name = azurerm_resource_group.emon_tf_group.name

  tags = {
    environment = "Terraform Emon"
  }
}

# Create subnet
resource "azurerm_subnet" "emon_tf_subnet" {
  name                 = "emonSubnet"
  resource_group_name  = azurerm_resource_group.emon_tf_group.name
  virtual_network_name = azurerm_virtual_network.emon_tf_network.name
  address_prefixes     = ["10.0.1.0/24"]
}

# Create public IPs
resource "azurerm_public_ip" "emon_tf_public_ip" {
  name                = "emonPublicIP"
  location            = var.az_location
  resource_group_name = azurerm_resource_group.emon_tf_group.name
  allocation_method   = "Dynamic"

  tags = {
    environment = "Terraform Emon"
  }
}

# Create Network Security Group and rule
resource "azurerm_network_security_group" "emon_tf_nsg" {
  name                = "emonNetworkSecurityGroup"
  location            = var.az_location
  resource_group_name = azurerm_resource_group.emon_tf_group.name

  security_rule {
    name                       = "Inbound Traffic"
    priority                   = 1001
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_ranges    = [22, 80, 443]
    source_address_prefix      = "*"
    destination_address_prefix = "*"
  }

  tags = {
    environment = "Terraform Emon"
  }
}

# Create network interface
resource "azurerm_network_interface" "emon_tf_nic" {
  name                = "emonNIC"
  location            = var.az_location
  resource_group_name = azurerm_resource_group.emon_tf_group.name

  ip_configuration {
    name                          = "emonNicConfiguration"
    subnet_id                     = azurerm_subnet.emon_tf_subnet.id
    private_ip_address_allocation = "Dynamic"
    public_ip_address_id          = azurerm_public_ip.emon_tf_public_ip.id
  }

  tags = {
    environment = "Terraform Emon"
  }
}

# Connect the security group to the network interface
resource "azurerm_network_interface_security_group_association" "emon" {
  network_interface_id      = azurerm_network_interface.emon_tf_nic.id
  network_security_group_id = azurerm_network_security_group.emon_tf_nsg.id
}

# Generate random text for a unique storage account name
resource "random_id" "randomId" {
  keepers = {
    # Generate a new ID only when a new resource group is defined
    resource_group = azurerm_resource_group.emon_tf_group.name
  }

  byte_length = 8
}

# Create storage account for boot diagnostics
resource "azurerm_storage_account" "emon_storage_account" {
  name                     = "diag${random_id.randomId.hex}"
  resource_group_name      = azurerm_resource_group.emon_tf_group.name
  location                 = var.az_location
  account_tier             = "Standard"
  account_replication_type = "LRS"

  tags = {
    environment = "Terraform Emon"
  }
}

# Create (and display) an SSH key
resource "tls_private_key" "emon_tallinn_ssh" {
  algorithm = "RSA"
  rsa_bits  = 4096
}

# Create virtual machine
resource "azurerm_linux_virtual_machine" "emon_tf_vm" {
  name                  = "emonVM"
  location              = var.az_location
  resource_group_name   = azurerm_resource_group.emon_tf_group.name
  network_interface_ids = [azurerm_network_interface.emon_tf_nic.id]
  size                  = "Standard_DS1_v2"

  os_disk {
    name                 = "emonOsDisk"
    caching              = "ReadWrite"
    storage_account_type = "Premium_LRS"
  }

  source_image_reference {
    publisher = var.image_publisher
    offer     = var.image_offer
    sku       = var.image_sku
    version   = var.image_version
  }

  computer_name                   = var.vm_name
  admin_username                  = var.admin_user
  disable_password_authentication = true
  admin_ssh_key {
    username   = var.admin_user
    public_key = tls_private_key.emon_tallinn_ssh.public_key_openssh
  }

  boot_diagnostics {
    storage_account_uri = azurerm_storage_account.emon_storage_account.primary_blob_endpoint
  }

  tags = {
    environment = "Terraform Emon"
  }
}

resource "azurerm_virtual_machine_extension" "vmext" {
  name                 = "${var.vm_name}-vmext"
  virtual_machine_id   = azurerm_linux_virtual_machine.emon_tf_vm.id
  publisher            = "Microsoft.Azure.Extensions"
  type                 = "CustomScript"
  type_handler_version = "2.0"

  #  settings = <<SETTINGS
  #    {
  #       "fileUris": ["https://raw.githubusercontent.com/emon-tallinn/ws/main/ansible/ansible_site_installer.sh"],
  #       "commandToExecute": "bash ansible_site_installer.sh"
  #    }
  #SETTINGS
  # ref. https://stackoverflow.com/questions/54088476/terraform-azurerm-virtual-machine-extension
  protected_settings = <<PROT
    {
        "script": "${base64encode(file(var.site_installer_file))}"
    }
    PROT

  tags = {
    environment = "Terraform Emon"
  }
}