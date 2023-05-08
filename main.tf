resource "azurerm_resource_group" "mvp" {
  location = var.region
  name     = var.resource_group_name
}

# Key Vault
module "key_vault" {
  source                                                = ".github.com/KPMG-UK/ewt-engineering-azure-infrastructure-modules//modules/key-vault?ref=0.3.4"
  region                                                = var.region
  resource_group_name                                   = azurerm_resource_group.mvp.name
  name                                                  = var.key_vault.name
  pricing_tier                                          = var.key_vault.pricing_tier
  soft_delete_retention_days                            = var.key_vault.soft_delete_retention_days
  enable_purge_protection                               = var.key_vault.enable_purge_protection
  enable_rbac_authorization                             = var.key_vault.enable_rbac_authorization
  enable_azure_disk_encryption_for_volume_encryption    = var.key_vault.enable_azure_disk_encryption_for_volume_encryption
  enable_azure_resource_manager_for_template_deployment = var.key_vault.enable_azure_resource_manager_for_template_deployment
  enable_azure_virtual_machines_for_deployment          = var.key_vault.enable_azure_virtual_machines_for_deployment
  network_access_control_lists                          = var.key_vault.network_access_control_lists
}

# Module VM
module "web_vms" {
  source = "github.com/KPMG-UK/ewt-engineering-azure-infrastructure-modules//modules/virtual-machine?ref=0.3.4"

  resource_group_name         = azurerm_resource_group.mvp.name
  region                      = var.region
  key_vault_id                = module.key_vault.id
  admin_username              = var.web_vms.admin_username
  application_security_groups = var.web_vms.application_security_groups
  availability_sets           = var.web_vms.availability_sets
  virtual_machines            = var.web_vms.virtual_machines
}

data "azurerm_subnet" "subnet" {
  name                 = each.value.subnet_name
  virtual_network_name = each.value.subnet_vnet_name
  resource_group_name  = each.value.vnet_rg_name
}

# Module Load Balancer
module "virtualmachine-load-balancer" {
  source = "github.com/KPMG-UK/ewt-engineering-azure-infrastructure-modules//modules/virtualmachine-load-balancer?ref=0.3.4"

  region                                = var.region
  resource_group_name                   = azurerm_resource_group.mvp.name
  name                                  = var.web_loadbalancer.name
  sku                                   = var.web_loadbalancer.sku
  sku_tier                              = var.web_loadbalancer.sku_tier
  backend_address_pool_name             = var.web_loadbalancer.backend_address_pool_name
  backend_address_pool_association_name = var.web_loadbalancer.backend_address_pool_association_name
  network_interface_ids = []
  frontend_configuration = {
    name                          = var.web_loadbalancer.frontend_configuration.name
    private_ip_address            = var.web_loadbalancer.frontend_configuration.private_ip_address
    private_ip_address_allocation = var.web_loadbalancer.frontend_configuration.private_ip_address_allocation
    private_ip_address_version    = var.web_loadbalancer.frontend_configuration.private_ip_address_version
    subnet_id                     = data.azurerm_subnet.subnet.id
  }

  load_balancer_rules = [
    {
      name                    = "Http"
      protocol                = "Tcp"
      frontend_port           = 80
      backend_port            = 80
      ip_configuration_name   = var.web_loadbalancer.name
      enable_floating_ip      = false
      disable_outbound_snat   = false
      idle_timeout_in_minutes = 15
      probe = {
        name                = "HttpProbe"
        protocol            = "Http"
        port                = 80
        interval_in_seconds = 15
        number_of_probes    = 2
        probe_threshold     = 2
      }
  }]

}