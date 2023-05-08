variable "prefix" {
  description = "Prefix for resources"
  type        = string
}

variable "location" {
  description = "Azure region to deploy the resources"
  type        = string
}

variable "admin_username" {
  description = "Administrator username for the VM"
  type        = string
}

variable "admin_password" {
  description = "Administrator password for the VM"
  type        = string
  sensitive   = true
}