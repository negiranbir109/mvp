# ----------------------------------#
# Login passwords, keys and secrets #
# ----------------------------------#

# Generate a unique password for each virtual machine
resource "random_password" "password" {
  for_each = { for vm in var.virtual_machines : vm.name => vm }
  length   = 16
  special  = true
}

# Add a local admin as a secret into Azure Key Vault
resource "azurerm_key_vault_secret" "localadmin" {
  name            = "local-admin"
  value           = var.admin_username
  key_vault_id    = var.key_vault_id
  content_type    = "text/plain"
  expiration_date = var.key_vault_secret_expiration_date
}

# Add generated password(s) as secret(s) into Azure Key Vault
resource "azurerm_key_vault_secret" "secret" {
  for_each        = { for vm in var.virtual_machines : vm.name => vm }
  name            = "${each.value.name}-localpass"
  value           = random_password.password[each.key].result
  key_vault_id    = var.key_vault_id
  content_type    = "text/plain"
  expiration_date = var.key_vault_secret_expiration_date
}

# --------------------------------------------------------#
# Resources corresponding with the virtual machine object #
# --------------------------------------------------------#

# Create an Availability Set(s)
resource "azurerm_availability_set" "as" {
  for_each                     = { for as in var.availability_sets : as.name => as }
  name                         = each.value.name
  resource_group_name          = var.resource_group_name
  location                     = var.region
  platform_fault_domain_count  = lookup(each.value, "platform_fault_domain_count", 2)
  platform_update_domain_count = lookup(each.value, "platform_update_domain_count", null)
  managed                      = lookup(each.value, "managed", null)

  lifecycle {
    ignore_changes = [
      # Ignore changes to tags, e.g. because a management agent (i.e. FinOps etc) updates these based on some ruleset managed elsewhere.
      tags,
    ]
  }
}

# Create an Applcication Security Group(s)
resource "azurerm_application_security_group" "asg" {
  for_each            = toset(var.application_security_groups)
  name                = each.value
  resource_group_name = var.resource_group_name
  location            = var.region

  lifecycle {
    ignore_changes = [
      # Ignore changes to tags, e.g. because a management agent (i.e. FinOps etc) updates these based on some ruleset managed elsewhere.
      tags,
    ]
  }
}

# ---------------------------------#
# Network Interface Card resources #
# ---------------------------------#

# Data block -> Get the ID of the subnet
data "azurerm_subnet" "subnets_ids" {
  for_each             = { for nic in local.nics : nic.name => nic }
  name                 = each.value.subnet_name
  virtual_network_name = each.value.subnet_vnet_name
  resource_group_name  = each.value.vnet_rg_name
}

# Create Network Interface Card(s)
resource "azurerm_network_interface" "nics" {
  for_each            = { for nic in local.nics : nic.name => nic }
  name                = each.value.name
  location            = var.region
  resource_group_name = var.resource_group_name

  ip_configuration {
    name                          = "internal"
    private_ip_address_allocation = "Dynamic"
    subnet_id                     = data.azurerm_subnet.subnets_ids[each.value.name].id
  }
  lifecycle {
    ignore_changes = [
      # Ignore changes to tags, e.g. because a management agent (i.e. FinOps etc) updates these based on some ruleset managed elsewhere.
      tags,
    ]
  }
}

# Association a NIC object(s) with the Application Security Group
resource "azurerm_network_interface_application_security_group_association" "asg_association" {
  for_each                      = { for nic in local.nics : nic.name => nic if nic.application_security_group_name != null }
  application_security_group_id = azurerm_application_security_group.asg[each.value.application_security_group_name].id
  network_interface_id          = azurerm_network_interface.nics[each.key].id
}


# Add NIC object(s) into Azure Load Balancer Backend Pool
resource "azurerm_network_interface_backend_address_pool_association" "lb_association" {
  for_each                = { for nic in local.nics : nic.name => nic if nic.lb_backendpool_id != null }
  network_interface_id    = azurerm_network_interface.nics[each.key].id
  ip_configuration_name   = "internal"
  backend_address_pool_id = each.value.lb_backendpool_id
}

# Add NIC objects(s) into Azure Application Gateway Backend Pool
resource "azurerm_network_interface_application_gateway_backend_address_pool_association" "appgw_association" {
  for_each                = { for nic in local.nics : nic.name => nic if nic.appgw_backendpool_id != null }
  network_interface_id    = azurerm_network_interface.nics[each.key].id
  ip_configuration_name   = "internal"
  backend_address_pool_id = each.value.appgw_backendpool_id
}

# ----------------#
# Virtual Machine #
# ----------------#

#checkov:skip=CKV_AZURE_93:Managed disk encryption feature is not described as required in the official documentation

# Create a virtual machine object(s)
resource "azurerm_windows_virtual_machine" "vm" {
  for_each = { for vm in var.virtual_machines : vm.name => vm }
  #checkov:skip=CKV_AZURE_50:Virtual Machine extension(s) are required for monitoring, domain joining, etc
  #checkov:skip=CKV_AZURE_151:The person who will use that module, has a possibility to on/off encryption at host
  name                = each.value.name
  resource_group_name = var.resource_group_name
  location            = var.region
  tags                = var.tags
  size                = each.value.size
  admin_username      = var.admin_username
  admin_password      = random_password.password[each.key].result

  identity {
    type = "SystemAssigned"
  }

  # Adding NIC object(s)
  network_interface_ids = flatten([for nic in local.nics : azurerm_network_interface.nics[nic.name].id if nic.associated_vm == each.value.name])

  # Availability Set Association
  availability_set_id = each.value.availability_set_name != null && each.value.availability_zone == null ? azurerm_availability_set.as[each.value.availability_set_name].id : null

  # Availability Zone Association
  zone = each.value.availability_set_name == null && each.value.availability_zone != null ? each.value.availability_zone : null

  # OS Disk Configuration
  os_disk {
    caching              = "ReadWrite"
    storage_account_type = "Premium_LRS"
    disk_size_gb         = 128
    name                 = "${each.value.name}-OsDisk"
  }

  # Encryption at host
  encryption_at_host_enabled = each.value.encryption_at_host_enabled == true ? true : null

  # Hybrid Benefit
  license_type = each.value.hybrid_beneift_license == true ? "Windows_Server" : null

  # Required flag for e.g. ADJoining extension
  allow_extension_operations = true

  source_image_reference {
    publisher = "MicrosoftWindowsServer"
    offer     = "WindowsServer"
    sku       = "2019-Datacenter"
    version   = "latest"
  }

  lifecycle {
    ignore_changes = [
      # Ignore changes to tags, e.g. because a management agent (i.e. FinOps etc) updates these based on some ruleset managed elsewhere.
      tags,
    ]
  }
}

# -------------#
# Data Disk(s) #
# -------------#

# Create Azure Managed Disk(s)
resource "azurerm_managed_disk" "disks" {
  for_each = { for disk in local.disks : disk.name => disk }
  #checkov:skip=CKV_AZURE_93:Managed disk encryption feature is not described as required in the official documentation
  name                 = each.value.name
  resource_group_name  = var.resource_group_name
  location             = var.region
  tags                 = var.tags
  storage_account_type = each.value.sku
  create_option        = "Empty"
  disk_size_gb         = each.value.size

  lifecycle {
    ignore_changes = [
      # Ignore changes to tags, e.g. because a management agent (i.e. FinOps etc) updates these based on some ruleset managed elsewhere.
      tags,
    ]
  }
}

# Associate Azure Managed Disk(s) with Virtual Machine(s)
resource "azurerm_virtual_machine_data_disk_attachment" "disks-association" {
  for_each           = { for disk in local.disks : disk.name => disk }
  managed_disk_id    = azurerm_managed_disk.disks[each.key].id
  virtual_machine_id = azurerm_windows_virtual_machine.vm[each.value.associated_vm].id
  lun                = each.value.lun
  caching            = each.value.caching
}

# ------------------#
# Backup protection #
# ------------------#

# Data block -> Get the Recovery Services Vault Backup Policy ID
data "azurerm_backup_policy_vm" "rsv_policy" {
  for_each            = { for vm in var.virtual_machines : vm.name => vm.backup_config if vm.backup_config != null }
  name                = each.value.backup_policy
  recovery_vault_name = each.value.rsv_name
  resource_group_name = each.value.rsv_rg
}

# Associate Virtual Machine(s) with Recovery Services Vault Backup Policy
resource "azurerm_backup_protected_vm" "protected_vms" {
  for_each            = data.azurerm_backup_policy_vm.rsv_policy
  resource_group_name = data.azurerm_backup_policy_vm.rsv_policy[each.key].resource_group_name
  recovery_vault_name = data.azurerm_backup_policy_vm.rsv_policy[each.key].recovery_vault_name
  source_vm_id        = azurerm_windows_virtual_machine.vm[each.key].id
  backup_policy_id    = data.azurerm_backup_policy_vm.rsv_policy[each.key].id
}

# -----------#
# Monitoring #
# -----------#

# Install Microsoft Monitoring Agent
resource "azurerm_virtual_machine_extension" "ama" {
  for_each                   = { for vm in var.virtual_machines : vm.name => vm if vm.dcr_config != null }
  name                       = "AzureMonitorAgent"
  tags                       = var.tags
  virtual_machine_id         = azurerm_windows_virtual_machine.vm[each.key].id
  publisher                  = "Microsoft.Azure.Monitor"
  type                       = "AzureMonitorWindowsAgent"
  type_handler_version       = "1.10"
  auto_upgrade_minor_version = "true"
  automatic_upgrade_enabled  = true

  lifecycle {
    ignore_changes = [
      # Ignore changes to tags, e.g. because a management agent (i.e. FinOps etc) updates these based on some ruleset managed elsewhere.
      tags,
    ]
  }
}

# Data block -> Get the Azure Monitor Data Collection Rule(s) ID
data "azurerm_monitor_data_collection_rule" "dcrs" {
  for_each            = { for dcr in local.dcrs : dcr.id => dcr }
  name                = each.value.name
  resource_group_name = each.value.location
}

# Associating Virtual Machine(s) with Azure Monitor Data Collection Rule(s)
resource "azurerm_monitor_data_collection_rule_association" "dcr_association" {
  for_each                = { for dcr in local.dcrs : dcr.id => dcr }
  name                    = format("%s", "${each.value.id}")
  target_resource_id      = azurerm_windows_virtual_machine.vm[each.value.associated_vm].id
  data_collection_rule_id = data.azurerm_monitor_data_collection_rule.dcrs[each.key].id
  description             = "${each.value.associated_vm} has been associated with DCR: ${each.value.name}"
  depends_on              = [azurerm_virtual_machine_extension.ama]
}

# ---------------#
# Domain Joining #
# ---------------#

# Data block -> Get the Azure Key Vault ID
data "azurerm_key_vault" "kvs_id" {
  for_each            = { for vm in var.virtual_machines : vm.name => vm.domain_joining if vm.domain_joining != null }
  name                = each.value.key_vault_name
  resource_group_name = each.value.key_vault_rg
}

# Data block -> Get the username account name for domain joining process
data "azurerm_key_vault_secret" "domain_join_user_name" {
  for_each     = { for vm in var.virtual_machines : vm.name => vm.domain_joining if vm.domain_joining != null }
  name         = each.value.ad_joining_username
  key_vault_id = data.azurerm_key_vault.kvs_id[each.key].id
}

# Data block -> Get the password for domain joining process
data "azurerm_key_vault_secret" "domain_join_user_password" {
  for_each     = { for vm in var.virtual_machines : vm.name => vm.domain_joining if vm.domain_joining != null }
  name         = each.value.ad_joining_password
  key_vault_id = data.azurerm_key_vault.kvs_id[each.key].id
}

# Joining Virtual Machine(s) to Active Directory
resource "azurerm_virtual_machine_extension" "domain-joining" {
  for_each                   = { for vm in var.virtual_machines : vm.name => vm.domain_joining if vm.domain_joining != null }
  name                       = "DomainJoinExtension"
  virtual_machine_id         = azurerm_windows_virtual_machine.vm[each.key].id
  publisher                  = "Microsoft.Compute"
  type                       = "JsonADDomainExtension"
  type_handler_version       = "1.3"
  auto_upgrade_minor_version = true
  depends_on                 = [azurerm_virtual_machine_extension.ama, azurerm_backup_protected_vm.protected_vms]

  settings = <<-SETTINGS
    {
      "Name": "${each.value.domain_fqdn}",
      "OUPath": "${each.value.ou_path}",
      "User": "${data.azurerm_key_vault_secret.domain_join_user_name[each.key].value}@${each.value.domain_fqdn}",
      "Restart": "true",
      "Options": "3"
    }
    SETTINGS

  protected_settings = <<SETTINGS
    {
        "Password": "${data.azurerm_key_vault_secret.domain_join_user_password[each.key].value}"
    }
    SETTINGS
}