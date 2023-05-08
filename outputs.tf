output "public_ip_address" {
  value       = azurerm_public_ip.example.ip_address
  description = "The public IP address of the Windows VM"
}

output "resource_group_name" {
  value       = azurerm_resource_group.example.name
  description = "The name of the resource group"
}

output "vm_name" {
  value       = azurerm_windows_virtual_machine.example.name
  description = "The name of the Windows VM"
}