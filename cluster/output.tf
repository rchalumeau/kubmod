/*output "01 Capacity" {
value = "${formatlist( "%s x %s [ %s ]", 
	list(var.master["count"], var.worker["count"], var.storekeeper["count"], var.bastion["count"], var.proxy["count"]), 
	list(var.master["name"], var.worker["name"], var.storekeeper["name"], var.bastion["name"], var.proxy["name"]), 
        list(var.master["size"], var.worker["size"], format("%s + disk %sGB", var.storekeeper["size"], var.storekeeper["storage"]) , var.bastion["size"], var.proxy["size"])
 	)}"
}

output "02 OS" {
	value = "CoreOS ${var.coreos_version}"
}

output "03 Assets" {
	value = "${formatlist( "%s : %s", keys(local.images), values(local.images) )}"
}
*/

output "Bastion FQDN" {
	value = "ssh -A ${var.boot_user}@${module.bastion_ip.fqdn}"
}

output "Bastion IP" {
        value = "ssh -A ${var.boot_user}@${module.bastion_ip.ip}"
}


output "Ingress FQDN" {
        value = "http://${module.ingress_ip.fqdn}"
}

