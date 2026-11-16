# The jumpbox: a Linux VM in the private jumpbox subnet, without a public IP, reached only through Azure Bastion (from
# the Bastion subnet, port 22) and signed in to with Entra ID. Its tools and the Entra SSH login extension are installed
# at the first session, once the session's NAT Gateway gives it outbound access (docs/DECISIONS.md D6); between sessions
# it is deallocated.

variable "jumpbox_size" {
  description = "VM size of the jumpbox (JUMPBOX_SIZE); one the subscription offers in the region (az vm list-skus)."
  type        = string
}

variable "jumpbox_login_object_ids" {
  description = "Entra object IDs, besides the deployer's, allowed to sign in to the jumpbox as administrators (JUMPBOX_LOGIN_OBJECT_IDS, comma-separated). Empty: the deployer only."
  type        = string
}

locals {
  jumpbox_name = "vm-jumpbox-${var.environment_name}"
  jumpbox_login_object_ids = toset(concat(
    [data.azurerm_client_config.current.object_id],
    [for id in split(",", var.jumpbox_login_object_ids) : trimspace(id) if trimspace(id) != ""],
  ))
}

resource "azurerm_network_security_group" "jumpbox" {
  name                = "nsg-jumpbox-${var.environment_name}"
  resource_group_name = azurerm_resource_group.main.name
  location            = var.location
  tags                = local.tags

  security_rule {
    name                       = "AllowSshFromBastion"
    priority                   = 100
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_address_prefix      = "10.40.0.0/26"
    source_port_range          = "*"
    destination_address_prefix = "*"
    destination_port_range     = "22"
  }

  # Everything else inbound, the rest of the virtual network included.
  security_rule {
    name                       = "DenyAllOtherInbound"
    priority                   = 4000
    direction                  = "Inbound"
    access                     = "Deny"
    protocol                   = "*"
    source_address_prefix      = "*"
    source_port_range          = "*"
    destination_address_prefix = "*"
    destination_port_range     = "*"
  }
}

resource "azurerm_subnet_network_security_group_association" "jumpbox" {
  subnet_id                 = local.network.subnet_ids["jumpbox"]
  network_security_group_id = azurerm_network_security_group.jumpbox.id
}

resource "azurerm_network_interface" "jumpbox" {
  name                = "nic-jumpbox-${var.environment_name}"
  resource_group_name = azurerm_resource_group.main.name
  location            = var.location
  tags                = local.tags

  ip_configuration {
    name                          = "private"
    subnet_id                     = local.network.subnet_ids["jumpbox"]
    private_ip_address_allocation = "Dynamic"
  }
}

# Azure requires an administrator key on a Linux VM even when people sign in with Entra ID. Azure generates the pair;
# only the public key is kept (the private key is in no state or output), so the account can't be used.
resource "azapi_resource" "jumpbox_admin_key" {
  type      = "Microsoft.Compute/sshPublicKeys@2024-07-01"
  name      = "sshkey-jumpbox-${var.environment_name}"
  parent_id = azurerm_resource_group.main.id
  location  = var.location
  tags      = local.tags
  body      = {}
}

resource "azapi_resource_action" "jumpbox_admin_key_pair" {
  type                   = "Microsoft.Compute/sshPublicKeys@2024-07-01"
  resource_id            = azapi_resource.jumpbox_admin_key.id
  action                 = "generateKeyPair"
  method                 = "POST"
  response_export_values = ["publicKey"]
}

resource "azurerm_linux_virtual_machine" "jumpbox" {
  name                  = local.jumpbox_name
  resource_group_name   = azurerm_resource_group.main.name
  location              = var.location
  size                  = var.jumpbox_size
  network_interface_ids = [azurerm_network_interface.jumpbox.id]
  # The v6 and later sizes have NVMe disk controllers only.
  disk_controller_type            = "NVMe"
  admin_username                  = "azureadmin"
  disable_password_authentication = true
  tags                            = local.tags

  admin_ssh_key {
    username   = "azureadmin"
    public_key = azapi_resource_action.jumpbox_admin_key_pair.output.publicKey
  }

  # The Entra SSH login extension needs the VM's own identity.
  identity {
    type = "SystemAssigned"
  }

  os_disk {
    caching              = "ReadWrite"
    storage_account_type = "StandardSSD_LRS"
  }

  source_image_reference {
    publisher = "Canonical"
    offer     = "ubuntu-24_04-lts"
    sku       = "server"
    version   = "latest"
  }

  # Managed boot diagnostics: the serial console and boot logs without a storage account.
  boot_diagnostics {}
}

resource "azurerm_role_assignment" "jumpbox_login" {
  for_each             = local.jumpbox_login_object_ids
  scope                = azurerm_linux_virtual_machine.jumpbox.id
  role_definition_name = "Virtual Machine Administrator Login"
  principal_id         = each.value
}

output "JUMPBOX_NAME" { value = local.jumpbox_name }
output "JUMPBOX_ID" { value = azurerm_linux_virtual_machine.jumpbox.id }
output "JUMPBOX_SUBNET_NAME" { value = "jumpbox" }
