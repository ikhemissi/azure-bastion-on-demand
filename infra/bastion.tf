# The permanent part of Azure Bastion: its public IP (Standard, static) in the AzureBastionSubnet's network. The host
# itself and the session's NAT Gateway are created and deleted by scripts (docs/DECISIONS.md D2, D6); their names are
# outputs so that the scripts and the reaper agree on them.

resource "azurerm_public_ip" "bastion" {
  name                = "pip-bastion-${var.environment_name}"
  resource_group_name = azurerm_resource_group.main.name
  location            = var.location
  allocation_method   = "Static"
  sku                 = "Standard"
  tags                = local.tags
}

output "BASTION_NAME" { value = "bas-${var.environment_name}" }
output "BASTION_PUBLIC_IP_NAME" { value = azurerm_public_ip.bastion.name }
output "NAT_GATEWAY_NAME" { value = "ng-jumpbox-${var.environment_name}" }
