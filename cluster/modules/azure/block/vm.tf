# Route vm to pod cidr
#${cidrsubnet(var.pod_cidr, 8, count.index + 1)}
# vm ip "${ cidrhost( cidrsubnet(var.cidr, 8, count.index + 1), 1)}"
resource "azurerm_route" "route" {
        count			= "${var.count}"

        name                    = "${azurerm_virtual_machine.vm.*.name[count.index]}"
        resource_group_name     = "${var.resourcegroup}"
        route_table_name        = "${var.routetable_name}"
        address_prefix          = "${cidrsubnet(var.pod_cidr, 8, count.index + 1)}"
        next_hop_type           = "VirtualAppliance"
	next_hop_in_ip_address	= "${ cidrhost( cidrsubnet(var.cidr, 8, count.index + 1), 1)}"
}

data "template_file" "ignition" {

  count                         = "${var.count}"
  template                      = "${var.ignition_tmpl}"
  vars {
        hostname                = "${var.name}${count.index + 1}"
	pod_cidr		= "${cidrsubnet(var.pod_cidr, 8, count.index + 1)}"
  }
}

resource "azurerm_availability_set" "as" {
    location 			= "${var.location}"
    name 			= "${var.name}-as"
    resource_group_name 	= "${var.resourcegroup}"
    managed			= true	
    # Limitation on uksouth... https://github.com/MicrosoftDocs/azure-docs/blob/master/includes/managed-disks-common-fault-domain-region-list.md
    #platform_fault_domain_count = 2
}

# Creation of virtual machines
resource "azurerm_virtual_machine" "vm" {

    name 			= "${var.name}${count.index + 1}"
    count 			= "${var.count}" 

    location 			= "${var.location}"
    availability_set_id 	= "${azurerm_availability_set.as.id}"

    resource_group_name 	= "${var.resourcegroup}"
    network_interface_ids     	= [ "${element(local.nics, count.index)}" ]
    vm_size 			= "${var.size}"

    # Definition of the OS version
    storage_image_reference {
        publisher 		= "CoreOS"
        offer 			= "CoreOS"
        sku 			= "stable"
        version 		= "${var.coreos_version}"
    }

    storage_os_disk {
        name              	= "${var.name}${count.index + 1}-os"
        caching           	= "ReadWrite"
        create_option     	= "FromImage"
        managed_disk_type 	= "${var.disk_type}"
        os_type           	= "linux"
    }

    os_profile {
        computer_name 		= "${var.name}${count.index + 1}"
        admin_username 		= "${var.boot_user}"
        admin_password 		= "Not!nUs3"
	    custom_data    		= "${base64encode("${data.template_file.ignition.*.rendered[count.index]}")}"
    }

    os_profile_linux_config {
        disable_password_authentication = true

        ssh_keys {
            path 		= "/home/${var.boot_user}/.ssh/authorized_keys"
            key_data 		= "${var.pub_key}"
        }
    }
}

locals {
	nics = [ "${ concat(azurerm_network_interface.nic-with-loadbalancer.*.id, azurerm_network_interface.nic-without-loadbalancer.*.id) }" ]
}

# Creation of the interface pointing at subnet with load balancer
resource "azurerm_network_interface" "nic-with-loadbalancer" {

    name 			= "${var.name}${count.index + 1}-nic"
    count                      = "${ var.type == "none" ? 0: var.count }"

    location 			= "${var.location}"
    resource_group_name		= "${var.resourcegroup}"

    enable_ip_forwarding        = true

    #network_security_group_id   = "${azurerm_network_security_group.nsg.id}" 
    ip_configuration {
        name 			= "${var.name}${count.index + 1}-ip"
        subnet_id 		= "${azurerm_subnet.subnet.id}"
        private_ip_address_allocation = "static"
        private_ip_address = "${cidrhost( cidrsubnet(var.cidr, 8, count.index + 1), 1)}"

        load_balancer_backend_address_pools_ids = [ "${azurerm_lb_backend_address_pool.lb.id}" ]
     }
}



# Creation of the interface pointing at subnet without load balancer
resource "azurerm_network_interface" "nic-without-loadbalancer" {

    name                        = "${var.name}${count.index + 1}-nic"
    count                      = "${ var.type == "none" ? var.count : 0 }"

    location                    = "${var.location}"
    resource_group_name         = "${var.resourcegroup}"

    enable_ip_forwarding	= true
    #network_security_group_id   = "${azurerm_network_security_group.nsg.id}"

    ip_configuration {
        name                    = "${var.name}${count.index + 1}-ip"
        subnet_id               = "${azurerm_subnet.subnet.id}"
        private_ip_address_allocation = "static"
        private_ip_address = "${ cidrhost( cidrsubnet(var.cidr, 8, count.index + 1), 1)}"
     }
}


