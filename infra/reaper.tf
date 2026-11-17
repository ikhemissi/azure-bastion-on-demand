# The reaper (docs/DECISIONS.md D4): a Flex Consumption function app (src/BastionReaper, azd service "reaper") that
# ends the sessions whose time is up. Its identity holds two custom roles, each with only what the reaper does:
# deleting the Bastion hosts and NAT Gateways and deallocating the jumpbox in the resource group, and detaching a NAT
# Gateway from the jumpbox subnet only (D6). A subnet write sends the subnet's links again, so it also needs to join
# the jumpbox's network security group (D10).

variable "reaper_deallocates_jumpbox" {
  description = "Whether the reaper deallocates the jumpbox when it ends a session (REAPER_DEALLOCATES_JUMPBOX)."
  type        = bool
}

resource "azurerm_role_definition" "reaper" {
  name        = "Bastion session reaper (${var.environment_name}-${local.token})"
  description = "Deletes the Bastion hosts and NAT Gateways of ended sessions and deallocates the jumpbox."
  scope       = azurerm_resource_group.main.id

  permissions {
    actions = [
      "Microsoft.Network/bastionHosts/read",
      "Microsoft.Network/bastionHosts/delete",
      "Microsoft.Network/natGateways/read",
      "Microsoft.Network/natGateways/delete",
      "Microsoft.Compute/virtualMachines/read",
      "Microsoft.Compute/virtualMachines/deallocate/action",
    ]
  }

  assignable_scopes = [azurerm_resource_group.main.id]
}

resource "azurerm_role_definition" "reaper_subnet" {
  name        = "Bastion session reaper, jumpbox subnet (${var.environment_name}-${local.token})"
  description = "Detaches a session's NAT Gateway from the jumpbox subnet, which keeps its network security group."
  scope       = azurerm_resource_group.main.id

  permissions {
    actions = [
      "Microsoft.Network/virtualNetworks/subnets/read",
      "Microsoft.Network/virtualNetworks/subnets/write",
      "Microsoft.Network/networkSecurityGroups/join/action",
    ]
  }

  assignable_scopes = [azurerm_resource_group.main.id]
}

module "reaper_storage" {
  source              = "./modules/storage-account"
  name                = "st${local.compact_name}reap${local.token}"
  resource_group_name = azurerm_resource_group.main.name
  location            = var.location
  tags                = local.tags
}

module "reaper" {
  source                    = "./modules/function-app-flex"
  name                      = "func-reaper-${var.environment_name}-${local.token}"
  plan_name                 = "asp-reaper-${var.environment_name}"
  resource_group_id         = azurerm_resource_group.main.id
  resource_group_name       = azurerm_resource_group.main.name
  location                  = var.location
  tags                      = local.tags
  azd_service_name          = "reaper"
  storage_account_id        = module.reaper_storage.id
  storage_account_name      = module.reaper_storage.name
  storage_blob_endpoint     = module.reaper_storage.primary_blob_endpoint
  deployment_container_name = "reaper-package"
  runtime_name              = "dotnet-isolated"
  runtime_version           = "10.0"
  instance_memory_mb        = 512
  maximum_instance_count    = 1

  app_settings = {
    SUBSCRIPTION_ID     = var.subscription_id
    RESOURCE_GROUP_NAME = azurerm_resource_group.main.name
    JUMPBOX_NAME        = azurerm_linux_virtual_machine.jumpbox.name
    DEALLOCATE_JUMPBOX  = tostring(var.reaper_deallocates_jumpbox)
  }

  application_insights_connection_string = module.monitoring.application_insights_connection_string
  role_assignments = {
    telemetry             = { scope = module.monitoring.application_insights_id, role = "Monitoring Metrics Publisher" }
    sessions              = { scope = azurerm_resource_group.main.id, role = azurerm_role_definition.reaper.name }
    subnet                = { scope = local.network.subnet_ids["jumpbox"], role = azurerm_role_definition.reaper_subnet.name }
    subnet_security_group = { scope = azurerm_network_security_group.jumpbox.id, role = azurerm_role_definition.reaper_subnet.name }
  }
}

output "REAPER_NAME" { value = module.reaper.name }
