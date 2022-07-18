## Azure Resource Group:-
resource "azurerm_resource_group" "rg" {
 name     = var.rg-name
 location = var.rg-location
}

## Azure User Assigned Managed Identities:-
resource "azurerm_user_assigned_identity" "az-usr-mid" {
  
 name                = var.usr-mid-name
 resource_group_name = azurerm_resource_group.rg.name
 location            = azurerm_resource_group.rg.location
  
 depends_on          = [azurerm_resource_group.rg]
 }