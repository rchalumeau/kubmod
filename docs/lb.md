# Load Balancers

The block allows to define the load balancing strategy of the group of VMs: internal load balancer, public facing load balancer or none. 
It allows also to define the load balancing rules and implicitly the associated probes (only TCP probes). 

## Input

For instance, 

  type                  = "public"
  public_ip             = "${module.ingress_ip.ip_id}"

    "lb_port" {
      http              = ["80", "Tcp", "30080"]
      https             = ["443", "Tcp", "30443"]
    }

- `type` : can be `public`, `private` or `none`

If `public`, `public_ip`must be provided (id of a static public ip generated in module `azure/publicip`) 

If `private`, `loadbalancer_private_ip` (ip defined in `cluster_constant.tf`) 

If `none`, no more configuration is needed. 

- `lb_port` is a map of arrays. The key detrmines the name of the rule, the array is defined as following : 
 1. frontend port : the port facing the client (for instance, 80 from internet to ingress) 
 2. protocol: TCP or UDP
 3. backend port: the port to reach on the VM (for instance, the node port of the ingress controller). The service must be reachable by the azure network. 
 
## Code

### load balancer

    resource "azurerm_lb" "lb" {
      count                         = "${var.type == "none" ? 0 : 1}"
      name                          = "${var.name}-lb"
      resource_group_name           = "${var.resourcegroup}"
      location                      = "${var.location}"
    
      frontend_ip_configuration {
        name                        = "${var.name}-ip"
        public_ip_address_id        = "${var.public_ip}"
        subnet_id                   = "${var.type == "private" ? var.subnet_id : ""}"
        private_ip_address          = "${var.loadbalancer_private_ip}"
        private_ip_address_allocation = "${var.type == "private" ? "Static" : "Dynamic" }"
      }
    }

The elvis operator allow not to create a load balancer iosf the type is none : `"${var.type == "none" ? 0 : 1}"` returns 0 if `none`, or 1 if not. It means that if none is set, the resource will loop 0 times, whiich means that it won't provision. 

The frontend IP configuration can be complex : it has not the same parameters if it is proivate or public. Here are the rules : 

 - The `var.public_ip`is defined with "" as default value. So if private lb, no public IP will be associated. 
 - Same with `var.loadbalancer_private_ip`, a public load balancer won't have private IP defined. 
 - If private, a subnet has to be provided. This is the line `"${var.type == "private" ? var.subnet_id : ""}"` with the same trick with elvis operator. 
 - The `private_ip_address_allocation` must be Static for private load balancer (as we push the IP), but dynamic on a public load balancer, so that we can have null value for the private IP.  

### Backend pool

The backend is provisioned only iof type is not `none` (elvis operator trick) 

The association of a backend to the pool is done via NIC configuration. This is implemented in the file `azure/block/vm.tf`

Two NIC are defined : one with load balancer (azurerm_network_interface.nic-with-loadbalancer) and one without (azurerm_network_interface.nic-without-loadbalancer). 
Two differences between them : 

 - `load_balancer_backend_address_pools_ids = [ "${azurerm_lb_backend_address_pool.lb.id}" ]` : Defined only in azurerm_network_interface.nic-with-loadbalancer, this is what plug the NIC to the backend pool. 
 - `count= "${ var.type == "none" ? var.count : 0 }"` in nic-without-loadbalancer and the reverse `count= "${ var.type == "none" ? 0 : var.count }"` in nic-with-loadbalancer

This means that in case of type none will be provisionned 0 nic-with-loadbalancer and `count` times nic-without-loadbalancer (as many as VMs). 
in case of type none will be provisionned `count` times nic-with-loadbalancer and 0 times nic-without-loadbalancer. 

To finish the trick, we have to associate the VM to the right NIC. 
This is done by the line : 

    locals {
        nics = [ "${ concat(azurerm_network_interface.nic-with-loadbalancer.*.id, azurerm_network_interface.nic-without-loadbalancer.*.id) }" ]
    }

This agregates both nic-with-loadbalancer and nic-with-loadbalancer arrays of ids. Thanks to the previous `none` elvis operator, one array is ampty and the other one has `count`elements. 
Therefore, the vm definition (azurerm_virtual_machine resource) can now link to its associated NIC : 
    network_interface_ids       = [ "${element(local.nics, count.index)}" ]

### Probe

The probe is quite obvious : it implements a TCP probe on the backend port of each rule. 

### Rule

we loop on the number of elements (arrays) of each map. The name of the rule is the key of the map. 
To understand the code, note the following : 
 - To retieve the key of the current array (count.index) : `element(keys(var.lb_port), count.index)`
 - To retieve the array associated with the previous key : `var.lb_port["${element(keys(var.lb_port), count.index)}"]`
 - To retrieve the element of the array, for instance the second one : `element(var.lb_port["${element(keys(var.lb_port), count.index)}"], 1)` 

The `frontend_ip_configuration_name` is the name of the frontend configuration from the load balancer (check first parapgraph), not the ip name itself. 
