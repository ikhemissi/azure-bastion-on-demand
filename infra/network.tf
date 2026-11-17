# The virtual network: the Bastion host's subnet, the jumpbox's (private: outbound only through a session's NAT Gateway,
# docs/DECISIONS.md D6), one for private endpoints of your own, and, with the sample targets, the internal Container
# Apps environment's and Key Vault's DNS zone. Module calls read their subnet from local.network and their private
# endpoint from local.private_endpoint. To reach resources in another virtual network, peer it: docs/peering.md.

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
  subnets = merge(
    {
      # Bastion needs this exact name, /26 or larger (Standard SKU).
      AzureBastionSubnet = { address_prefix = "10.40.0.0/26" }
      jumpbox            = { address_prefix = "10.40.1.0/27", default_outbound_access = false }
      private-endpoints  = { address_prefix = "10.40.2.0/27" }
    },
    var.deploy_sample_targets ? {
      container-apps = { address_prefix = "10.40.3.0/27", delegation = "Microsoft.App/environments" }
    } : {}
  )
  # Only with the sample targets: a virtual network links to one zone per name, so a zone of your own (an existing
  # privatelink.vaultcore.azure.net) can then be linked here (docs/peering.md).
  private_dns_zones = var.deploy_sample_targets ? ["privatelink.vaultcore.azure.net"] : []
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
