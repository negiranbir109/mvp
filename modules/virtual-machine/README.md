# Standard Build VM with WS 2019 module

Terraform module for creating Azure Virtual Machine running on Windows Server 2019 operating system.<br>
This is a comperhensive module that also creates the following corresponding resources:
- Application Security Group
- Availability Set
- Network Interface Card(s)
- Azure Managed Disk(s)
- Enable the monitoring
- Enable the backup protection
- Joining a virtual machine into the Active Directory
<!-- BEGIN_TF_DOCS -->


## Providers

| Name | Version |
|------|---------|
| <a name="provider_azurerm"></a> [azurerm](#provider\_azurerm) | n/a |
| <a name="provider_random"></a> [random](#provider\_random) | n/a |

## Resources

| Name | Type |
|------|------|
| [azurerm_application_security_group.asg](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/application_security_group) | resource |
| [azurerm_availability_set.as](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/availability_set) | resource |
| [azurerm_backup_protected_vm.protected_vms](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/backup_protected_vm) | resource |
| [azurerm_key_vault_secret.localadmin](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/key_vault_secret) | resource |
| [azurerm_key_vault_secret.secret](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/key_vault_secret) | resource |
| [azurerm_managed_disk.disks](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/managed_disk) | resource |
| [azurerm_monitor_data_collection_rule_association.dcr_association](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/monitor_data_collection_rule_association) | resource |
| [azurerm_network_interface.nics](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/network_interface) | resource |
| [azurerm_network_interface_application_gateway_backend_address_pool_association.appgw_association](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/network_interface_application_gateway_backend_address_pool_association) | resource |
| [azurerm_network_interface_application_security_group_association.asg_association](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/network_interface_application_security_group_association) | resource |
| [azurerm_network_interface_backend_address_pool_association.lb_association](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/network_interface_backend_address_pool_association) | resource |
| [azurerm_virtual_machine_data_disk_attachment.disks-association](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/virtual_machine_data_disk_attachment) | resource |
| [azurerm_virtual_machine_extension.ama](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/virtual_machine_extension) | resource |
| [azurerm_virtual_machine_extension.domain-joining](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/virtual_machine_extension) | resource |
| [azurerm_windows_virtual_machine.vm](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/windows_virtual_machine) | resource |
| [random_password.password](https://registry.terraform.io/providers/hashicorp/random/latest/docs/resources/password) | resource |
| [azurerm_backup_policy_vm.rsv_policy](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/data-sources/backup_policy_vm) | data source |
| [azurerm_key_vault.kvs_id](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/data-sources/key_vault) | data source |
| [azurerm_key_vault_secret.domain_join_user_name](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/data-sources/key_vault_secret) | data source |
| [azurerm_key_vault_secret.domain_join_user_password](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/data-sources/key_vault_secret) | data source |
| [azurerm_monitor_data_collection_rule.dcrs](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/data-sources/monitor_data_collection_rule) | data source |
| [azurerm_subnet.subnets_ids](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/data-sources/subnet) | data source |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_admin_username"></a> [admin\_username](#input\_admin\_username) | Virtual machine local administrator user name. | `string` | `"vmlocaladmin"` | no |
| <a name="input_application_security_groups"></a> [application\_security\_groups](#input\_application\_security\_groups) | List of application security group | `list(string)` | n/a | yes |
| <a name="input_availability_sets"></a> [availability\_sets](#input\_availability\_sets) | List of availability sets configurations | `map` | `{}` | no |
| <a name="input_key_vault_id"></a> [key\_vault\_id](#input\_key\_vault\_id) | ID of the Azure Key Vault where local credentials for VM(s) will be stored. | `string` | n/a | yes |
| <a name="input_key_vault_secret_expiration_date"></a> [key\_vault\_secret\_expiration\_date](#input\_key\_vault\_secret\_expiration\_date) | KeyVault secret expiration date. | `string` | n/a | yes |
| <a name="input_region"></a> [region](#input\_region) | Resource deployment location. | `string` | `"uksouth"` | no |
| <a name="input_resource_group_name"></a> [resource\_group\_name](#input\_resource\_group\_name) | Resource group name. | `string` | n/a | yes |
| <a name="input_tags"></a> [tags](#input\_tags) | A map of tags to add to the resources created using this module. | `map(string)` | `{}` | no |
| <a name="input_virtual_machines"></a> [virtual\_machines](#input\_virtual\_machines) | List of virtual machines configurations. | <pre>list(object({<br>    name = string<br>    size = string<br>    nic_config = list(object({<br>      subnet_name                     = string<br>      vnet_name                       = string<br>      vnet_rg_name                    = string<br>      appgw_backendpool_id            = optional(string)<br>      lb_backendpool_id               = optional(string)<br>      application_security_group_name = optional(string)<br>    }))<br>    availability_set_name      = optional(string)<br>    availability_zone          = optional(number)<br>    encryption_at_host_enabled = optional(bool)<br>    hybrid_beneift_license     = optional(bool)<br>    data_disks = optional(list(object({<br>      disk_size    = number<br>      disk_sku     = string<br>      disk_caching = string<br>    })))<br>    dcr_config = optional(list(object({<br>      dcr_name = string<br>      dcr_rg   = string<br>    })))<br>    backup_config = optional(object({<br>      rsv_rg        = string<br>      rsv_name      = string<br>      backup_policy = string<br>    }))<br>    domain_joining = optional(object({<br>      key_vault_name      = string<br>      key_vault_rg        = string<br>      ad_joining_username = string<br>      ad_joining_password = string<br>      domain_fqdn         = string<br>      ou_path             = string<br>    }))<br><br>  }))</pre> | n/a | yes |

## Outputs

| Name | Description |
|------|-------------|
| <a name="output_vms_id"></a> [vms\_id](#output\_vms\_id) | Map of virtual machine ids  <br>                  <br>Example:<br>  {  <br>    vm-1 = "vm 1 id"  <br>    vm-2 = "vm 2 id"<br>  } |
<!-- END_TF_DOCS -->