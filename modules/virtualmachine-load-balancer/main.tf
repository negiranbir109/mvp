resource "azurerm_lb" "lb" {
  location            = var.region
  name                = var.name
  resource_group_name = var.resource_group_name
  sku                 = var.sku
  sku_tier            = var.sku_tier
  tags                = var.tags
  frontend_ip_configuration {
    name                          = var.name
    private_ip_address            = var.frontend_configuration.private_ip_address
    private_ip_address_allocation = var.frontend_configuration.private_ip_address_allocation
    private_ip_address_version    = var.frontend_configuration.private_ip_address_version
    subnet_id                     = var.frontend_configuration.subnet_id

  }
  lifecycle {
    ignore_changes = [tags]
  }
}

resource "azurerm_lb_backend_address_pool" "loadbalncerbckpool" {
  loadbalancer_id = azurerm_lb.lb.id
  name            = var.backend_address_pool_name
}

resource "azurerm_network_interface_backend_address_pool_association" "backend_address_pool_association_name" {
  for_each                = toset(var.network_interface_ids)
  network_interface_id    = each.value
  ip_configuration_name   = var.backend_address_pool_association_name
  backend_address_pool_id = azurerm_lb_backend_address_pool.loadbalncerbckpool.id
}

//commenting out as this is not required as of now as per requirement
/*resource "azurerm_lb_nat_rule" "loadbalancer_nat_rule" {
  for_each                       = { for lbnat in var.remote_port : lbnat.name => lbnat }
  backend_port                   = each.value.backend_port
  frontend_ip_configuration_name = each.value.ip_configuration_name
  loadbalancer_id                = azurerm_lb.lb.id
  name                           = "VM-${each.key}"
  protocol                       = each.value.protocol
  resource_group_name            = var.resource_group_name
  frontend_port                  = each.value.frontend_port
  frontend_port_start            = each.value.frontend_port_start
  frontend_port_end              = each.value.frontend_port_end
  backend_address_pool_id        = azurerm_lb_backend_address_pool.loadbalncerbckpool.id


}
//For example


resource "azurerm_lb_nat_rule" "example1" {
  resource_group_name            = var.resource_group_name
  loadbalancer_id                = azurerm_lb.azlb.id
  name                           = "RDPAccess"
  protocol                       = "Tcp"
  frontend_port_start            = 3000
  frontend_port_end              = 3389
  backend_port                   = 3389
  backend_address_pool_id        = azurerm_lb_backend_address_pool.azlbckpool.id
  frontend_ip_configuration_name = "PublicIPAddress"
}*/




resource "azurerm_lb_probe" "probe" {
  for_each            = { for lr in var.load_balancer_rules : lr.name => lr if lr.probe != {} }
  loadbalancer_id     = azurerm_lb.lb.id
  name                = each.key
  port                = each.value.backend_port
  interval_in_seconds = each.value.probe.interval_in_seconds
  number_of_probes    = each.value.probe.number_of_probes
  protocol            = each.value.protocol
  request_path        = each.value.probe.request_path
}



resource "azurerm_lb_rule" "rule" {
  for_each                       = { for lr in var.load_balancer_rules : lr.name => lr }
  backend_port                   = each.value.backend_port
  frontend_ip_configuration_name = each.value.ip_configuration_name
  frontend_port                  = each.value.frontend_port
  loadbalancer_id                = azurerm_lb.lb.id
  name                           = each.key
  protocol                       = each.value.protocol
  backend_address_pool_ids       = [azurerm_lb_backend_address_pool.loadbalncerbckpool.id]
  disable_outbound_snat          = each.value.disable_outbound_snat
  enable_floating_ip             = each.value.enable_floating_ip
  idle_timeout_in_minutes        = each.value.idle_timeout_in_minutes
  probe_id                       = each.value.probe != {} ? azurerm_lb_probe.probe[each.key].id : null
}

