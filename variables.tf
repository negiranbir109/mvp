variable "region" {
  description = "Deployment region of the resources created using this module."
  type        = string
  default     = "uksouth"
}

variable "resource_group_name" {
  description = "value"
  type        = string
}

variable "key_vault" {
  description = "Configuration object - Key Vault."
  type = object({
    name                                                  = string
    pricing_tier                                          = string
    soft_delete_retention_days                            = optional(number, 90)
    enable_purge_protection                               = optional(bool, true)
    enable_rbac_authorization                             = optional(bool, false)
    enable_azure_virtual_machines_for_deployment          = optional(bool, false)
    enable_azure_resource_manager_for_template_deployment = optional(bool, false)
    enable_azure_disk_encryption_for_volume_encryption    = optional(bool, false)
    enable_private_endpoint                               = optional(bool, false)
    network_access_control_lists = optional(object({
      bypass                     = string
      default_action             = string
      ip_rules                   = optional(list(string), [])
      virtual_network_subnet_ids = optional(list(string), [])
    }))
  })
}

variable "web_vms" {
  type = object({
    admin_username              = string
    application_security_groups = list(string)
    availability_sets           = list(object({ name = string }))
    virtual_machines = list(object({
      name = string
      size = string
      nic_config = list(object({
        vnet_rg_name                    = string
        vnet_name                       = string
        subnet_name                     = string
        application_security_group_name = optional(string)
      }))
      availability_set_name      = optional(string)
      encryption_at_host_enabled = bool
      data_disks = list(object({
        disk_size    = number
        disk_sku     = string
        disk_caching = string
      }))
    }))
  })
}

variable "web_loadbalancer" {
  type = object({
    name = string
    sku = string
    sku_tier = string
    backend_address_pool_name = string
    backend_address_pool_association_name = string
    frontend_configuration = object({
      name = string
      private_ip_address = string
      private_ip_address_allocation = string
      private_ip_address_version = string
    })
  })
}