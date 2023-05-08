variable "region" {
  description = "Deployment region of the resources created using this module."
  type        = string
  default     = "uksouth"
}

variable "resource_group_name_index" {
  description = "Resource group name index part (postfix)."
  type        = string
  default     = "0001"
}

variable "virtual_network_name_index" {
  description = "Virtual network name index part (postfix)."
  type        = string
  default     = "001"
}

variable "virtual_network_address_space" {
  description = "The address space that is used the virtual network. You can supply more than one address space."
  type        = list(string)
  default     = ["10.4.0.0/16"]
}