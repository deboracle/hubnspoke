# here we define all of the resources for the hub

# create resource group for the hub
resource "azurerm_resource_group" "deborah_hub_rg" {
  name     = "deborah-hub-rg"
  location = "West US"

# create the hub virtual network
resource "azurerm_virtual_network" "deborah_hub_vnet" {
  name                = "deborah-hub-vnet"
  address_space       = ["10.0.0.0/16"]
  location            = azurerm_resource_group.deborah_hub_rg.location
  resource_group_name = azurerm_resource_group.deborah_hub_rg.name
}

# define the public IP address resource
resource "azurerm_public_ip" "deborah_public_ip" {
  name                = "deborah-public-ip"
  location            = "West US"
  resource_group_name = azurerm_resource_group.deborah_hub_rg.name
  sku = "Standard"
  allocation_method = "Static"
}

# create the hub vnet subnet for the gateway
resource "azurerm_subnet" "deborah_hub_gateway_subnet" {
    name             = "deborah_hub_gateway_subnet"
    resource_group_name  = azurerm_resource_group.deborah_hub_rg.name
    virtual_network_name = azurerm_virtual_network.deborah_hub_vnet.name
    address_prefixes     = ["10.0.0.0/24"]
}

# create the hub vpn gateway
resource "azurerm_virtual_network_gateway" "deborah_hub_vpn_gateway" {
  name                = "deborah-hub-vpn-gateway"
  location            = azurerm_resource_group.deborah_hub_rg.location
  resource_group_name = azurerm_resource_group.deborah_hub_rg.name
  type                = "Vpn"
  vpn_type            = "RouteBased"
  sku                 = "VpnGw1"

  ip_configuration {
    name      = "gatewayIpConfig"
    public_ip_address_id = azurerm_public_ip.deborah_public_ip.id
    subnet_id = azurerm_subnet.deborah_hub_gateway_subnet.id
  }
}

# create the hub p2s connection
resource "azurerm_virtual_network_gateway_connection" "deborah_hub_p2s_connection" {
    name                      = "deborah-hub-p2s-connection"
    location                  = azurerm_resource_group.deborah_hub_rg.location
    resource_group_name       = azurerm_resource_group.deborah_hub_rg.name
    virtual_network_gateway_id = azurerm_virtual_network_gateway.deborah_hub_vpn_gateway.id
    type                      = "ExpressRoute"  # Specify the type of connection, it could be "Vpn" or "ExpressRoute"
}

# create the hub firewall
resource "azurerm_firewall" "deborah_hub_firewall" {
  name                = "deborah-hub-firewall"
  location            = azurerm_resource_group.deborah_hub_rg.location
  resource_group_name = azurerm_resource_group.deborah_hub_rg.name
  sku_name            = "AZFW_Hub"  # Specify the desired SKU name
  sku_tier            = "Standard"  # Specify the desired SKU tier
}  

# create the firewall policy
resource "azurerm_firewall_policy" "deborah_hub_firewall_policy" {
  name                = "deborah-hub-firewall-policy"
  location            = azurerm_resource_group.deborah_hub_rg.location
  resource_group_name = azurerm_resource_group.deborah_hub_rg.name
}

# create the hub acr with private endpoint
resource "azurerm_container_registry" "deborah_hub_acr" {
  name                = "deborahhubacr"
  resource_group_name = azurerm_resource_group.deborah_hub_rg.name
  location            = azurerm_resource_group.deborah_hub_rg.location
  sku                 = "Standard"
}

resource "azurerm_subnet" "deborah_hub_acr_private_endpoint_subnet" {
    name                 = "deborah-hub-acr-private-endpoint-subnet"
    resource_group_name  = azurerm_resource_group.deborah_hub_rg.name
    virtual_network_name = azurerm_virtual_network.deborah_hub_vnet.name
    address_prefixes     = ["10.0.1.0/24"]  # Specify the subnet CIDR block
  }
  
resource "azurerm_private_endpoint" "deborah_hub_acr_private_endpoint" {
  name                = "deborah-hub-acr-private-endpoint"
  location            = azurerm_resource_group.deborah_hub_rg.location
  resource_group_name = azurerm_resource_group.deborah_hub_rg.name

  subnet_id                    = azurerm_subnet.deborah_hub_acr_private_endpoint_subnet.id
  private_service_connection {
    name                           = "deborah-acrPrivateEndpoint"
    private_connection_resource_id = azurerm_container_registry.deborah_hub_acr.id
    is_manual_connection           = false
    subresource_names              = ["registry"]
  }
}

# create the hub log analytics workspace
resource "azurerm_log_analytics_workspace" "deborah_hub_log_analytics_workspace" {
  name                = "deborah-hub-log-analytics-workspace"
  location            = azurerm_resource_group.deborah_hub_rg.location
  resource_group_name = azurerm_resource_group.deborah_hub_rg.name
  sku                 = "PerGB2018"
  retention_in_days   = 30
}