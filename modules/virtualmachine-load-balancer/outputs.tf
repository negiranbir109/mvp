output "backend_address_pool_id" {
  description = "the id for the azurerm_lb_backend_address_pool resource"
  value       = azurerm_lb_backend_address_pool.loadbalncerbckpool.id
}

output "frontend_ip_configuration" {
  description = "the frontend_ip_configuration for the azurerm_lb resource"
  value       = azurerm_lb.lb.frontend_ip_configuration
}

output "id" {
  description = "the id for the azurerm_lb resource"
  value       = azurerm_lb.lb.id
}


/*output "azurerm_lb_nat_rule_ids" {
  description = "the ids for the azurerm_lb_nat_rule resources"
  value       = azurerm_lb_nat_rule.loadbalancer_nat_rule[*].id
}*/
