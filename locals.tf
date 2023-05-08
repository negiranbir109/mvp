locals {
  resource_group_name  = format("%sinfapp%s", contains(["uksouth", "ukwest"], var.region) ? "uk" : "go", var.resource_group_name_index)
  virtual_network_name = format("%sAZRVNet%s", contains(["uksouth", "ukwest"], var.region) ? "UK" : "GO", var.virtual_network_name_index)
}