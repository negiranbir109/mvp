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
  default = "Load balancer name"
  type    = string
}
variable "frontend_configuration" {
  description = "Load balancer resource configuration"
  type = object({
    zones                         = optional(list(string))
    subnet_id                     = optional(string)
    private_ip_address            = optional(string)
    private_ip_address_allocation = optional(string, "Dynamic")
    private_ip_address_version    = optional(string, "IPv4")

  })
}
variable "load_balancer_rules" {
  description = "Frontend load balancer rules"
  type = list(object({
    name                    = string
    ip_configuration_name   = string
    frontend_port           = number
    backend_port            = number
    protocol                = string
    disable_outbound_snat   = optional(bool, false) // Is snat enabled for this Load Balancer rule
    enable_floating_ip      = optional(bool, false)
    idle_timeout_in_minutes = optional(number, 4)
    probe = optional(object({
      probe_threshold     = optional(number, 1)
      interval_in_seconds = optional(number, 5)
      number_of_probes    = optional(number, 2)
      request_path        = optional(string)
    }))
  }))
}

//commenting out as this is not required as of now as per requirement
/*variable "remote_port" {
  description = "Protocols to be used for remote vm access. [protocol, backend_port]. "
  type = list(object({
    name                    = string
    protocol                = string
    ip_configuration_name   = string
    frontend_port           = optional(number, "")
    backend_port            = number
    frontend_port_start     = optional(number, "")
    frontend_port_end       = optional(number, "")
    idle_timeout_in_minutes = optional(number, 4)
    enable_floating_ip      = optional(bool, false)

  }))
}*/

variable "sku" {
  description = " The SKU of the Azure Load Balancer. Accepted values are Basic and Standard."
  type        = string
}

variable "sku_tier" {
  description = " The SKU tier of this Load Balancer. Possible values are `Global` and `Regional`. Defaults to `Regional`. Changing this forces a new resource to be created."
  type        = string
}

variable "backend_address_pool_name" {
  description = "Name of the backend address pool."
  type        = string
}

variable "backend_address_pool_association_name" {
  description = "Name of the ip configuration for backend address pool association."
  type        = string
}

variable "tags" {
  type        = map(string)
  description = " A mapping of tags to assign to the load balancer."

}

variable "network_interface_ids" {
  type        = list(string)
  description = " NIC id of virtual machine"

}







