variable "resource_group_name" {
  description = "Resource group name."
  type        = string
}

variable "region" {
  description = "Deployment region of the resources created using this module."
  type        = string
  default     = "uksouth"
}

variable "name" {
  description = "Azure Key Vault name must only contain alphanumeric characters and dashes and cannot start with a number."
  type        = string
}

variable "tags" {
  description = "A map of tags to add to the resources created using this module."
  type        = map(string)
  default     = {}
}

variable "pricing_tier" {
  description = "Azure Key Vault service is offered in two service tiers: `standard` and `premium`"
  type        = string
  default     = "standard"
  validation {
    condition     = contains(["standard", "premium"], var.pricing_tier)
    error_message = "Azure Key Vaults are offered in two service tiers — standard and premium"
  }
}

variable "soft_delete_retention_days" {
  description = <<-EOT
                  The number of days that items should be retained for once soft-deleted. 
                  It can be configured to between 7 to 90 days. Once it has been set, it cannot be changed or removed.
                EOT
  default     = 90
}

variable "enable_purge_protection" {
  description = <<-EOT
                  Enabling purge protection on a key vault is an irreversible action. 
                  Once the purge protection property has been set to `true`, it cannot be changed or removed.
                  
                  Values:

                    `false` = Disable purge protection (allow key vault and objects to be purged during retention period)

                    `true` = Enable purge protection (enforce a mandatory retention period for deleted vaults and vault objects)
                EOT
  default     = true
}

variable "enable_azure_virtual_machines_for_deployment" {
  description = "Specifies whether Azure Virtual Machines are permitted to retrieve certificates stored as secrets from the key vault."
  default     = false
}

variable "enable_azure_resource_manager_for_template_deployment" {
  description = "Specifies whether Azure Resource Manager is permitted to retrieve secrets from the key vault."
  default     = false
}

variable "enable_azure_disk_encryption_for_volume_encryption" {
  description = "Specifies whether Azure Disk Encryption is permitted to retrieve secrets from the vault and unwrap keys."
  default     = false
}

variable "enable_rbac_authorization" {
  description = <<-EOT
                Specifies whether Azure Key Vault uses Role Based Access Control (RBAC) for authorization of data actions.

                Read [Azure RBAC documentation](https://learn.microsoft.com/en-us/azure/key-vault/general/rbac-guide?tabs=azure-cli) for providing access to Key Vault keys, certificates, and secrets with an Azure role-based access control.
                EOT
  default     = false
}

variable "access_policies" {
  description = "List of access policy permissions."
  default     = []
}

variable "network_access_control_lists" {
  description = <<-EOT
                  Network ACLs (access control lists) specifies what services can access your key vault.

                  bypass                      = (Required) Specifies which traffic can bypass the network rules. Possible values are `AzureServices` and `None`.
                  default_action              = (Required) The Default Action to use when no rules match from `ip_rules / virtual_network_subnet_ids`. Possible values are `Allow` and `Deny`.
                  ip_rules                    = (Optional) One or more IP Addresses, or CIDR Blocks which should be able to access the Key Vault.
                  virtual_network_subnet_ids  = (Optional) One or more Subnet IDs which should be able to access this Key Vault.
                EOT
  type = object({
    bypass                     = string
    default_action             = string
    ip_rules                   = list(string)
    virtual_network_subnet_ids = list(string)
  })
  default = {
    bypass                     = "AzureServices"
    default_action             = "Deny"
    ip_rules                   = []
    virtual_network_subnet_ids = []
  }
}

variable "certificate_owners_contacts" {
  description = "Allows certificate owners to provide contact information for notification about life-cycle events of expiration and renewal of certificate."
  type = list(object({
    email = string
    name  = string
    phone = string
  }))
  default = []
}

variable "enable_private_endpoint" {
  description = <<-EOT
                An Azure Private Endpoint is a network interface that connects you privately and securely to a service powered by Azure Private Link. 
                The private endpoint uses a private IP address from your VNet, effectively bringing the service into your VNet.
                EOT
  default     = false
}

variable "keyvault_dns_a_record_ttl" {
  description = "The Time To Live (TTL) of the DNS record in seconds."
  default     = 300
}

variable "virtual_network_id" {
  description = "Existing Virtual Network."
  default     = null
}

variable "subnet_id" {
  description = "Existing Subnet within a Virtual Network."
  default     = null
}