# The virtual network: the Bastion host's subnet, the jumpbox's (private: outbound only through a session's NAT Gateway,
# docs/DECISIONS.md D6), the private endpoints' and the internal Container Apps environment's. Module calls read their
# subnet from local.network and their private endpoint from local.private_endpoint.

locals {
  vnet_name = "vnet-${var.environment_name}-${local.token}"
}

module "network" {
  source              = "./modules/network"
  name                = local.vnet_name
  resource_group_name = azurerm_resource_group.main.name
  location            = var.location
  tags                = local.tags
  address_space       = "10.40.0.0/16"
  subnets = {
    # Bastion needs this exact name, /26 or larger (Standard SKU).
    AzureBastionSubnet = { address_prefix = "10.40.0.0/26" }
    jumpbox            = { address_prefix = "10.40.1.0/27", default_outbound_access = false }
    private-endpoints  = { address_prefix = "10.40.2.0/27" }
    container-apps     = { address_prefix = "10.40.3.0/27", delegation = "Microsoft.App/environments" }
  }
  private_dns_zones = ["privatelink.vaultcore.azure.net"]
}

locals {
  network = {
    subnet_ids = module.network.subnet_ids
  }
  private_endpoint = {
    subnet_id            = module.network.subnet_ids["private-endpoints"]
    private_dns_zone_ids = module.network.private_dns_zone_ids
  }
}

output "VNET_NAME" { value = local.vnet_name }
