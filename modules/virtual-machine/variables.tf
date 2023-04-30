variable "resource_group_name" {
  description = "Resource group name."
  type        = string
}

variable "region" {
  description = "Resource deployment location."
  type        = string
  default     = "uksouth"
}

variable "tags" {
  description = "A map of tags to add to the resources created using this module."
  type        = map(string)
  default     = {}
}

variable "key_vault_id" {
  description = "ID of the Azure Key Vault where local credentials for VM(s) will be stored."
  type        = string
}

variable "key_vault_secret_expiration_date" {
  description = "KeyVault secret expiration date."
  type        = string
  default     = null
}

variable "admin_username" {
  description = "Virtual machine local administrator user name."
  type        = string
  default     = "vmlocaladmin"
}

variable "availability_sets" {
  description = "List of availability sets configurations"
  default     = {}
}

variable "application_security_groups" {
  description = "List of application security group"
  type        = list(string)
}

variable "virtual_machines" {
  description = "List of virtual machines configurations."
  type = list(object({
    name = string
    size = string
    nic_config = list(object({
      subnet_name                     = string
      vnet_name                       = string
      vnet_rg_name                    = string
      appgw_backendpool_id            = optional(string)
      lb_backendpool_id               = optional(string)
      application_security_group_name = optional(string)
    }))
    availability_set_name      = optional(string)
    availability_zone          = optional(number)
    encryption_at_host_enabled = optional(bool)
    hybrid_beneift_license     = optional(bool)
    data_disks = optional(list(object({
      disk_size    = number
      disk_sku     = string
      disk_caching = string
    })))
    dcr_config = optional(list(object({
      dcr_name = string
      dcr_rg   = string
    })))
    backup_config = optional(object({
      rsv_rg        = string
      rsv_name      = string
      backup_policy = string
    }))
    domain_joining = optional(object({
      key_vault_name      = string
      key_vault_rg        = string
      ad_joining_username = string
      ad_joining_password = string
      domain_fqdn         = string
      ou_path             = string
    }))

  }))
}