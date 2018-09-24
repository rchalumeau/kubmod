resource "azurerm_subnet" "subnet" {
    address_prefix              = "${var.cidr}"
    name                        = "${var.name}-subnet"
    network_security_group_id   = "${azurerm_network_security_group.nsg.id}"
    resource_group_name         = "${var.resourcegroup}"
    virtual_network_name        = "${var.network_name}"
    route_table_id              = "${var.routetable}"
}


# NSG provisioning
resource "azurerm_network_security_group" "nsg" {
    location 			= "${var.location}"
    name 			= "${var.name}-nsg"
    resource_group_name 	= "${var.resourcegroup}"
}


# Inboud rules
resource "azurerm_network_security_rule" "inbound_rules" {

    count			= "${length(var.inbound_rules)}"
    direction			= "Inbound"

    name                        = "in-${element(keys(var.inbound_rules), count.index)}"

    priority			= "${100 + element(var.inbound_rules["${element(keys(var.inbound_rules), count.index)}"],0) * 10}"

    access                      = "${element(var.inbound_rules["${element(keys(var.inbound_rules), count.index)}"], 1)}"
    source_address_prefix       = "${element(var.inbound_rules["${element(keys(var.inbound_rules), count.index)}"], 2)}"
    source_port_range           = "${element(var.inbound_rules["${element(keys(var.inbound_rules), count.index)}"], 3)}"

    destination_address_prefix  = "${element(var.inbound_rules["${element(keys(var.inbound_rules), count.index)}"], 4)}"
    destination_port_range      = "${element(var.inbound_rules["${element(keys(var.inbound_rules), count.index)}"], 5)}"

    protocol                    = "${element(var.inbound_rules["${element(keys(var.inbound_rules), count.index)}"], 6)}"

    network_security_group_name = "${azurerm_network_security_group.nsg.name}"
    resource_group_name         = "${var.resourcegroup}"
}

# Outbound rules
resource "azurerm_network_security_rule" "outbound_rules" {

    count                       = "${length(var.outbound_rules)}"
    direction                   = "Outbound"

    name                        = "out-${element(keys(var.outbound_rules), count.index)}"

    priority                    = "${100 + element(var.outbound_rules["${element(keys(var.outbound_rules), count.index)}"],0) * 10}"
    access                      = "${element(var.outbound_rules["${element(keys(var.outbound_rules), count.index)}"], 1)}"
    source_address_prefix       = "${element(var.outbound_rules["${element(keys(var.outbound_rules), count.index)}"], 2)}"
    source_port_range           = "${element(var.outbound_rules["${element(keys(var.outbound_rules), count.index)}"], 3)}"

    destination_address_prefix  = "${element(var.outbound_rules["${element(keys(var.outbound_rules), count.index)}"], 4)}"
    destination_port_range      = "${element(var.outbound_rules["${element(keys(var.outbound_rules), count.index)}"], 5)}"

    protocol                    = "${element(var.outbound_rules["${element(keys(var.outbound_rules), count.index)}"], 6)}"

    network_security_group_name = "${azurerm_network_security_group.nsg.name}"
    resource_group_name         = "${var.resourcegroup}"
}

# Add allowance to internal subnet communication, VMs and pods
resource "azurerm_network_security_rule" "internal_subnet_inbound_rules" {
    direction                   = "Inbound"
    name                        = "in-internal"
    priority                    = "100"
    access                      = "Allow"
    source_address_prefix       = "${var.cidr}"
    source_port_range           = "*"
    destination_address_prefix  = "${var.cidr}"
    destination_port_range      = "*"
    protocol                    = "Tcp"
    network_security_group_name = "${azurerm_network_security_group.nsg.name}"
    resource_group_name         = "${var.resourcegroup}"
}

resource "azurerm_network_security_rule" "internal_subnet_outbound_rules" {
    direction                   = "Outbound"
    name                        = "out-internal"
    priority                    = "100"
    access                      = "Allow"
    source_address_prefix       = "${var.cidr}"
    source_port_range           = "*"
    destination_address_prefix  = "${var.cidr}"
    destination_port_range      = "*"
    protocol                    = "Tcp"
    network_security_group_name = "${azurerm_network_security_group.nsg.name}"
    resource_group_name         = "${var.resourcegroup}"
}

resource "azurerm_network_security_rule" "internal_pod_subnet_inbound_rules" {
    direction                   = "Inbound"
    name                        = "in-pod-internal"
    priority                    = "101"
    access                      = "Allow"
    source_address_prefix       = "${var.pod_cidr}"
    source_port_range           = "*"
    destination_address_prefix  = "${var.pod_cidr}"
    destination_port_range      = "*"
    protocol                    = "Tcp"
    network_security_group_name = "${azurerm_network_security_group.nsg.name}"
    resource_group_name         = "${var.resourcegroup}"
}

resource "azurerm_network_security_rule" "internal_pod_subnet_outbound_rules" {
    direction                   = "Outbound"
    name                        = "out-pod-internal"
    priority                    = "101"
    access                      = "Allow"
    source_address_prefix       = "${var.pod_cidr}"
    source_port_range           = "*"
    destination_address_prefix  = "${var.pod_cidr}"
    destination_port_range      = "*"
    protocol                    = "Tcp"
    network_security_group_name = "${azurerm_network_security_group.nsg.name}"
    resource_group_name         = "${var.resourcegroup}"
}


