# Load balancer
resource "azurerm_lb" "lb" {
    count                   = "${var.type == "none" ? 0 : 1}"
    name                    = "${var.name}-lb"
    resource_group_name     = "${var.resourcegroup}"
    location                = "${var.location}"

    frontend_ip_configuration {
        name                          = "${var.name}-ip"
        public_ip_address_id          = "${var.public_ip}"
        subnet_id                     = "${var.type == "private" ? azurerm_subnet.subnet.id : ""}"
        private_ip_address            = "${var.loadbalancer_private_ip}"
        private_ip_address_allocation = "${var.type == "private" ? "Static" : "Dynamic" }"
    }
}

resource "azurerm_lb_backend_address_pool" "lb" {
    count                   = "${var.type == "none" ? 0 : 1}"
    resource_group_name     = "${var.resourcegroup}"
    loadbalancer_id         = "${azurerm_lb.lb.id}"
    name                    = "BackEndAddressPool"
}


resource "azurerm_lb_probe" "lb" {
    count                   = "${length(var.lb_port)}"

    resource_group_name     = "${var.resourcegroup}"
    loadbalancer_id         = "${azurerm_lb.lb.id}"
    name                    = "${element(keys(var.lb_port), count.index)}"
    protocol                = "Tcp"

    port                    = "${  element( var.lb_port["${element(keys(var.lb_port), count.index)}"], length( var.lb_port["${element(keys(var.lb_port), count.index)}"] ) - 1 ) }"

    interval_in_seconds     = "${var.lb_probe_interval}"
    number_of_probes        = "${var.lb_probe_unhealthy_threshold}"
}

resource "azurerm_lb_rule" "lb" {
    count                          = "${length(var.lb_port)}"

    resource_group_name            = "${var.resourcegroup}"
    loadbalancer_id                = "${azurerm_lb.lb.id}"
    name                           = "${element(keys(var.lb_port), count.index)}"
    protocol                       = "${element(var.lb_port["${element(keys(var.lb_port), count.index)}"], 1)}"
    frontend_port                  = "${element(var.lb_port["${element(keys(var.lb_port), count.index)}"], 0)}"
    backend_port                   = "${element(var.lb_port["${element(keys(var.lb_port), count.index)}"], 2)}"
    frontend_ip_configuration_name = "${var.name}-ip"
    enable_floating_ip             = false
    backend_address_pool_id        = "${azurerm_lb_backend_address_pool.lb.id}"
    idle_timeout_in_minutes        = 5
    probe_id                       = "${element(azurerm_lb_probe.lb.*.id,count.index)}"
    depends_on                     = ["azurerm_lb_probe.lb"]
}
