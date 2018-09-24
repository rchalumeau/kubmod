output "provider" {
	value = "azurerm.cluster"
}

output "cluster_name" {
    	value = "${azurerm_resource_group.cluster.name}"
}

output "cloud_config_id" {
    	value = "${data.ignition_file.cloud_config.id}"
}

output "network_name" {
        value = "${azurerm_virtual_network.network.name}"
}

/*output "subnet_id" {
	value = "${azurerm_subnet.subnet.id}"
}*/

output "routetable_name" {
	value = "${azurerm_route_table.routetable.name}"
}

output "routetable_id" {
        value = "${azurerm_route_table.routetable.id}"
}

