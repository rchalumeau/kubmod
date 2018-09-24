variable "name" {}
variable "location" {}
variable "resourcegroup" {}

resource "azurerm_public_ip" "ip" {
  name                          = "${var.name}-publicIP"
  location                      = "${var.location}"
  resource_group_name           = "${var.resourcegroup}"
  public_ip_address_allocation  = "Static"
  domain_name_label		= "${var.resourcegroup}-${var.name}"
}

output "ip_id" {
	value = "${azurerm_public_ip.ip.id}"
}

output "ip" {
        value = "${azurerm_public_ip.ip.ip_address}"
}

output "fqdn" {
	 value = "${azurerm_public_ip.ip.fqdn}"
}

