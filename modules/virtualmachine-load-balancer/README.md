<!-- BEGIN_TF_DOCS -->


## Providers

| Name | Version |
|------|---------|
| <a name="provider_azurerm"></a> [azurerm](#provider\_azurerm) | n/a |

## Resources

| Name | Type |
|------|------|
| [azurerm_lb.lb](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/lb) | resource |
| [azurerm_lb_backend_address_pool.loadbalncerbckpool](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/lb_backend_address_pool) | resource |
| [azurerm_lb_probe.probe](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/lb_probe) | resource |
| [azurerm_lb_rule.rule](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/lb_rule) | resource |
| [azurerm_network_interface_backend_address_pool_association.backend_address_pool_association_name](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/network_interface_backend_address_pool_association) | resource |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_backend_address_pool_association_name"></a> [backend\_address\_pool\_association\_name](#input\_backend\_address\_pool\_association\_name) | Name of the ip configuration for backend address pool association. | `string` | n/a | yes |
| <a name="input_backend_address_pool_name"></a> [backend\_address\_pool\_name](#input\_backend\_address\_pool\_name) | Name of the backend address pool. | `string` | n/a | yes |
| <a name="input_frontend_configuration"></a> [frontend\_configuration](#input\_frontend\_configuration) | Load balancer resource configuration | <pre>object({<br>    zones                         = optional(list(string))<br>    subnet_id                     = optional(string)<br>    private_ip_address            = optional(string)<br>    private_ip_address_allocation = optional(string, "Dynamic")<br>    private_ip_address_version    = optional(string, "IPv4")<br><br>  })</pre> | n/a | yes |
| <a name="input_load_balancer_rules"></a> [load\_balancer\_rules](#input\_load\_balancer\_rules) | Frontend load balancer rules | <pre>list(object({<br>    name                    = string<br>    ip_configuration_name   = string<br>    frontend_port           = number<br>    backend_port            = number<br>    protocol                = string<br>    disable_outbound_snat   = optional(bool, false) // Is snat enabled for this Load Balancer rule<br>    enable_floating_ip      = optional(bool, false)<br>    idle_timeout_in_minutes = optional(number, 4)<br>    probe = optional(object({<br>      probe_threshold     = optional(number, 1)<br>      interval_in_seconds = optional(number, 5)<br>      number_of_probes    = optional(number, 2)<br>      request_path        = optional(string)<br>    }))<br>  }))</pre> | n/a | yes |
| <a name="input_name"></a> [name](#input\_name) | n/a | `string` | `"Load balancer name"` | no |
| <a name="input_network_interface_ids"></a> [network\_interface\_ids](#input\_network\_interface\_ids) | NIC id of virtual machine | `list(string)` | n/a | yes |
| <a name="input_region"></a> [region](#input\_region) | Deployment region of the resources created using this module. | `string` | `"uksouth"` | no |
| <a name="input_resource_group_name"></a> [resource\_group\_name](#input\_resource\_group\_name) | Resource group name. | `string` | n/a | yes |
| <a name="input_sku"></a> [sku](#input\_sku) | The SKU of the Azure Load Balancer. Accepted values are Basic and Standard. | `string` | n/a | yes |
| <a name="input_sku_tier"></a> [sku\_tier](#input\_sku\_tier) | The SKU tier of this Load Balancer. Possible values are `Global` and `Regional`. Defaults to `Regional`. Changing this forces a new resource to be created. | `string` | n/a | yes |
| <a name="input_tags"></a> [tags](#input\_tags) | A mapping of tags to assign to the load balancer. | `map(string)` | n/a | yes |

## Outputs

| Name | Description |
|------|-------------|
| <a name="output_backend_address_pool_id"></a> [backend\_address\_pool\_id](#output\_backend\_address\_pool\_id) | the id for the azurerm\_lb\_backend\_address\_pool resource |
| <a name="output_frontend_ip_configuration"></a> [frontend\_ip\_configuration](#output\_frontend\_ip\_configuration) | the frontend\_ip\_configuration for the azurerm\_lb resource |
| <a name="output_id"></a> [id](#output\_id) | the id for the azurerm\_lb resource |
<!-- END_TF_DOCS -->