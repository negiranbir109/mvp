output "vms_id" {
  description = <<-EOT
                  Map of virtual machine ids
                  
                  Example:
                    {
                      vm-1 = "vm 1 id"
                      vm-2 = "vm 2 id"
                    }
                EOT

  value = { for vm in var.virtual_machines : vm.name => azurerm_windows_virtual_machine.vm[vm.name].id }
}