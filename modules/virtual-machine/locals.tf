locals {
  # Variable that holds information for data disk creation
  disks = flatten([
    for vm_key, virtual_machine in var.virtual_machines : [
      for disk_key, disk in virtual_machine.data_disks : {
        name          = format("%s%d", "${virtual_machine.name}-DataDisk-", tonumber(disk_key) + 1)
        size          = disk.disk_size
        sku           = disk.disk_sku
        caching       = disk.disk_caching
        associated_vm = virtual_machine.name
        lun           = tonumber(disk_key) + 1
      }
    ] if virtual_machine.data_disks != null
  ])

  # Variable that holds information for NIC(s) creation 
  nics = flatten([
    for vm_key, virtual_machine in var.virtual_machines : [
      for nic_key, nic in virtual_machine.nic_config : {
        name                            = format("%s%d", "${virtual_machine.name}-nic-", tonumber(nic_key) + 1)
        subnet_name                     = nic.subnet_name
        subnet_vnet_name                = nic.vnet_name
        vnet_rg_name                    = nic.vnet_rg_name
        appgw_backendpool_id            = lookup(nic, "appgw_backendpool_id", null)
        lb_backendpool_id               = lookup(nic, "lb_backendpool_id", null)
        application_security_group_name = lookup(nic, "application_security_group_name", null)
        associated_vm                   = virtual_machine.name
      }
    ]
  ])

  # Variable that holds information for configuring monitoring
  dcrs = flatten([
    for vm_key, virtual_machine in var.virtual_machines : [
      for dcr_key, dcr in virtual_machine.dcr_config : {
        id            = format("%s%s%s", "${virtual_machine.name}-", dcr.dcr_name, "-${dcr.dcr_rg}")
        name          = dcr.dcr_name
        location      = dcr.dcr_rg
        associated_vm = virtual_machine.name
      }
    ] if virtual_machine.dcr_config != null
  ])
}