
provider "azurerm" {
    alias 			= "azure"

    subscription_id 		= "${var.subscription_id}"
    client_id       		= "${var.client_id}"
    client_secret   		= "${var.client_secret}"
    tenant_id       		= "${var.tenant_id}"
}


# Create a resource group
resource "azurerm_resource_group" "cluster" {
    name     			= "${var.name}"
    location 			= "${var.location}"
    tags {
      environment          	= "${var.environment}"
    }
}

#virtual network in the resource group
resource "azurerm_virtual_network" "network" {
  name                          = "${var.name}-net"
  address_space                 = [ "${var.cidr}"  ]
  location                      = "${var.location}"
  resource_group_name           = "${azurerm_resource_group.cluster.name}"
}

resource "azurerm_route_table" "routetable" {
  name                		= "${var.name}-rt"
  location            		= "${var.location}"
  resource_group_name 		= "${azurerm_resource_group.cluster.name}"
}

# Subnet provisionning
/*
resource "azurerm_subnet" "subnet" {
    address_prefix              = "${var.subnet_cidr}"
    name                        = "${var.name}-subnet"
    #network_security_group_id   = "${azurerm_network_security_group.nsg.id}"
    resource_group_name         = "${var.name}"
    virtual_network_name        = "${azurerm_virtual_network.network.name}"
    route_table_id 		= "${azurerm_route_table.routetable.id}"
}
*/

data "null_data_source" "cloud_provider" {
  inputs = {
    "cloud"                      = "azurepubliccloud"
    "tenantId"                   = "${var.tenant_id}"
    "subscriptionId"             = "${var.subscription_id}"
    "aadClientId"                = "${var.client_id}"
    "aadClientSecret"            = "${var.client_secret}"
    "resourceGroup"              = "${var.name}"
    "location"                   = "${var.location}"
    "subnetName"                 = "${var.primary_block}-subnet"
    "securityGroupName"          = "${var.primary_block}-nsg"
    "vnetName"                   = "${azurerm_virtual_network.network.name}"
    "routeTableName"		 = "${azurerm_route_table.routetable.name}"
    "primaryAvailabilitySetName" = "${var.primary_block}-as"
  }
}

data "ignition_file" "cloud_config" {
  filesystem = "root"
  path       = "/etc/kubernetes/azure.json"
  mode       = 0644

  content {
    content = "${jsonencode(data.null_data_source.cloud_provider.inputs)}"
  }
}


