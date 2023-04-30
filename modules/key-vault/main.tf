
/* -----------------------------------------------------------------------
  Azure enviornment and configuration :
  ------------------------------------------------------------------------ */

data "azurerm_client_config" "current" {}

data "azuread_user" "ad_users" {
  count               = length(local.azure_ad_user_principal_names)
  user_principal_name = local.azure_ad_user_principal_names[count.index]
}

data "azuread_group" "ad_groups" {
  count        = length(local.azure_ad_group_names)
  display_name = local.azure_ad_group_names[count.index]
}

data "azuread_service_principal" "ad_service_principals" {
  count        = length(local.azure_ad_service_principal_names)
  display_name = local.azure_ad_service_principal_names[count.index]
}


/* -----------------------------------------------------------------------
  Key vault :
  ------------------------------------------------------------------------ */

resource "azurerm_key_vault" "kv" {
  name                            = var.name
  location                        = var.region
  resource_group_name             = var.resource_group_name
  tenant_id                       = data.azurerm_client_config.current.tenant_id
  sku_name                        = var.pricing_tier
  enabled_for_deployment          = var.enable_azure_virtual_machines_for_deployment
  enabled_for_template_deployment = var.enable_azure_resource_manager_for_template_deployment
  enabled_for_disk_encryption     = var.enable_azure_disk_encryption_for_volume_encryption
  enable_rbac_authorization       = var.enable_rbac_authorization
  soft_delete_retention_days      = var.soft_delete_retention_days
  purge_protection_enabled        = var.enable_purge_protection
  tags                            = var.tags

  dynamic "network_acls" {
    for_each = var.network_access_control_lists != null ? [1] : []
    content {
      bypass                     = var.network_access_control_lists.bypass
      default_action             = var.network_access_control_lists.default_action
      ip_rules                   = var.network_access_control_lists.ip_rules
      virtual_network_subnet_ids = var.network_access_control_lists.virtual_network_subnet_ids
    }
  }

  dynamic "contact" {
    for_each = var.certificate_owners_contacts
    content {
      email = each.value.email
      name  = each.value.name
      phone = each.value.phone
    }
  }

  lifecycle {
    ignore_changes = [
      # Ignore changes to tags, e.g. because a management agent (i.e. FinOps etc) updates these based on some ruleset managed elsewhere.
      tags,
    ]
  }
}

resource "azurerm_key_vault_access_policy" "self_access_policy" {
  key_vault_id            = azurerm_key_vault.kv.id
  tenant_id               = data.azurerm_client_config.current.tenant_id
  object_id               = data.azurerm_client_config.current.object_id
  certificate_permissions = ["Backup", "Create", "Delete", "DeleteIssuers", "Get", "GetIssuers", "Import", "List", "ListIssuers", "ManageContacts", "ManageIssuers", "Purge", "Recover", "Restore", "SetIssuers", "Update"]
  key_permissions         = ["Backup", "Create", "Decrypt", "Delete", "Encrypt", "Get", "Import", "List", "Purge", "Recover", "Restore", "Sign", "UnwrapKey", "Update", "Verify", "WrapKey", "Release", "Rotate", "GetRotationPolicy", "SetRotationPolicy"]
  secret_permissions      = ["Backup", "Delete", "Get", "List", "Purge", "Recover", "Restore", "Set"]
  storage_permissions     = ["Backup", "Delete", "DeleteSAS", "Get", "GetSAS", "List", "ListSAS", "Purge", "Recover", "RegenerateKey", "Restore", "Set", "SetSAS", "Update"]
}

resource "azurerm_key_vault_access_policy" "access_policies" {
  for_each                = toset(local.access_policies_distinct)
  key_vault_id            = azurerm_key_vault.kv.id
  tenant_id               = data.azurerm_client_config.current.tenant_id
  object_id               = each.value.object_id
  certificate_permissions = each.value.certificate_permissions
  key_permissions         = each.value.key_permissions
  secret_permissions      = each.value.secret_permissions
  storage_permissions     = each.value.storage_permissions
}


/* -----------------------------------------------------------------------
  Private link :
  ------------------------------------------------------------------------ */

resource "azurerm_private_endpoint" "keyvault_private_endpoint" {
  count               = var.enable_private_endpoint ? 1 : 0
  name                = var.name
  location            = var.region
  resource_group_name = var.resource_group_name
  subnet_id           = var.subnet_id
  tags                = var.tags

  private_service_connection {
    name                           = format("%s-keyvault-privatelink", var.name)
    is_manual_connection           = false
    private_connection_resource_id = azurerm_key_vault.kv.id
    subresource_names              = ["vault"]
  }

  lifecycle {
    ignore_changes = [
      # Ignore changes to tags, e.g. because a management agent (i.e. FinOps etc) updates these based on some ruleset managed elsewhere.
      tags,
    ]
  }
}

data "azurerm_private_endpoint_connection" "keyvault_private_endpoint_connection" {
  count               = var.enable_private_endpoint ? 1 : 0
  depends_on          = [azurerm_key_vault.kv, azurerm_private_endpoint.keyvault_private_endpoint]
  name                = azurerm_private_endpoint.keyvault_private_endpoint.0.name
  resource_group_name = var.resource_group_name
}

resource "azurerm_private_dns_zone" "keyvault_private_dns_zone" {
  count               = var.enable_private_endpoint ? 1 : 0
  name                = "privatelink.vaultcore.azure.net"
  resource_group_name = var.resource_group_name
  tags                = var.tags

  lifecycle {
    ignore_changes = [
      # Ignore changes to tags, e.g. because a management agent (i.e. FinOps etc) updates these based on some ruleset managed elsewhere.
      tags,
    ]
  }
}

resource "azurerm_private_dns_zone_virtual_network_link" "keyvault_virtual_network_link" {
  count                 = var.enable_private_endpoint ? 1 : 0
  name                  = "keyvault-vnet-link"
  resource_group_name   = var.resource_group_name
  private_dns_zone_name = azurerm_private_dns_zone.keyvault_private_dns_zone.0.name
  virtual_network_id    = var.virtual_network_id

  lifecycle {
    ignore_changes = [
      # Ignore changes to tags, e.g. because a management agent (i.e. FinOps etc) updates these based on some ruleset managed elsewhere.
      tags,
    ]
  }
}

resource "azurerm_private_dns_a_record" "keyvault_dns_a_record" {
  count               = var.enable_private_endpoint ? 1 : 0
  name                = azurerm_key_vault.kv.name
  zone_name           = azurerm_private_dns_zone.keyvault_private_dns_zone.0.name
  resource_group_name = var.resource_group_name
  ttl                 = var.keyvault_dns_a_record_ttl
  records             = [data.azurerm_private_endpoint_connection.keyvault_private_endpoint_connection.0.private_service_connection.0.private_ip_address]

}

/* -----------------------------------------------------------------------
  Diagnostics : (TODO)

    This feature is differed as we need to understand a bit more how each application , 
    line of business and platform are going to forward diagnostics data into a Azure log analytics workspace.

    Assumption was to provide Log Analytics Workspace as a reference. 
    If this is the case platform need to create LAW and made available it before key-vaults are deployed.
  ------------------------------------------------------------------------ */