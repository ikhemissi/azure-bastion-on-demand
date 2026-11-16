# What a session reaches, both reachable from the virtual network only: Key Vault behind a private endpoint, with
# public network access off (a data service), and a web app in an internal Container Apps environment, whose names
# resolve through a private DNS zone (a private web app). docs/DECISIONS.md D5.

module "key_vault" {
  source                        = "./modules/key-vault"
  name                          = "kv-${substr(var.environment_name, 0, 10)}-${local.token}"
  resource_group_name           = azurerm_resource_group.main.name
  location                      = var.location
  tags                          = local.tags
  secrets_officer_object_ids    = [data.azurerm_client_config.current.object_id]
  public_network_access_enabled = false
  private_endpoint              = local.private_endpoint
}

module "container_apps_environment" {
  source                     = "./modules/container-apps-environment"
  name                       = "cae-${var.environment_name}-${local.token}"
  resource_group_name        = azurerm_resource_group.main.name
  location                   = var.location
  tags                       = local.tags
  log_analytics_workspace_id = module.monitoring.log_analytics_workspace_id
  subnet_id                  = local.network.subnet_ids["container-apps"]
  internal                   = true
}

resource "azurerm_container_app" "private_web_app" {
  name                         = "ca-hello-${var.environment_name}"
  resource_group_name          = azurerm_resource_group.main.name
  container_app_environment_id = module.container_apps_environment.id
  revision_mode                = "Single"
  workload_profile_name        = "Consumption"
  tags                         = local.tags

  # External to the environment, which is internal: reachable from the virtual network only.
  ingress {
    external_enabled = true
    target_port      = 80

    traffic_weight {
      latest_revision = true
      percentage      = 100
    }
  }

  template {
    min_replicas = 0
    max_replicas = 1

    container {
      name = "hello"
      # Microsoft's Container Apps quickstart page, pinned by digest.
      image  = "mcr.microsoft.com/k8se/quickstart@sha256:3a4d93c34c6753f24765ab17a36f1754aee9b02082b7d9553d17697b9e8252c4"
      cpu    = 0.25
      memory = "0.5Gi"
    }
  }
}

# The internal environment's apps are <app>.<default domain>, at the environment's static IP, in no public DNS.
resource "azurerm_private_dns_zone" "container_apps" {
  name                = module.container_apps_environment.default_domain
  resource_group_name = azurerm_resource_group.main.name
  tags                = local.tags
}

resource "azurerm_private_dns_a_record" "container_apps_wildcard" {
  name                = "*"
  zone_name           = azurerm_private_dns_zone.container_apps.name
  resource_group_name = azurerm_resource_group.main.name
  ttl                 = 300
  records             = [module.container_apps_environment.static_ip_address]
}

resource "azurerm_private_dns_zone_virtual_network_link" "container_apps" {
  name                  = "container-apps"
  resource_group_name   = azurerm_resource_group.main.name
  private_dns_zone_name = azurerm_private_dns_zone.container_apps.name
  virtual_network_id    = module.network.virtual_network_id
  tags                  = local.tags
}

output "KEY_VAULT_NAME" { value = module.key_vault.name }
output "KEY_VAULT_URI" { value = module.key_vault.uri }
output "PRIVATE_WEB_APP_URL" { value = "https://${azurerm_container_app.private_web_app.ingress[0].fqdn}" }
