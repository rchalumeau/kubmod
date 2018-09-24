# NSG rules

## Inputs

Two inputs are expected as maps in the instanciation of a block : `inbound_rules`and `outbound_rules`
Both inbound and outbound rules are defined in the same way (only the direction changes) : we define maps of array. The map key will be used as the NSG rule name. 

 1. priority (integer) : the requests are compared to the rules in the order of priorities. The first one to match is selcted. A map is not ordered, so therefore, so as to ensure the right order of the rules, we explicitely define it. 
 2. permission (Allow or Deny) : is the rule open or closed
 3. Source CIDR or tags (LoadBalancer, Internet)
 4. Source ports 
 5. Destination CIDR or tags
 6. Destination port (`start-end` for a port range)
 7. Protocol (Tcp, Udp or *)

Example: 

    "inbound_rules" {
                "ssh-from-bastion"      = [1, "Allow", "${local.bastion_cidr}",                 "*", "${local.master_cidr}", "22", "Tcp"]
         }

    "outbound_rules" {
                "master-to-nodes"       = [1, "Allow", "${local.master_cidr}", "*",             "${local.vm_cidr}",     "10250", "Tcp"]
        }


**Important note : Thanks to our [networking](networking.md), the sources and destinations can be VMs or pods CIDR.**

## Code

The code is in modules/azure/block/networking.tf

The code allows to provision a NSG in azure. 

Then, two resources `azurerm_network_security_rule` are defined : `outbound_rules` and `outbound_rules? . Both follow the exact same logic. 

    count                       = "${length(var.inbound_rules)}"
    
This will loop over the map of arrays passed as input (respectively outbound_rules and inbound rules). 

To retrieve the map key of the line, `element(keys(var.inbound_rules), count.index)`

To retrieve the array associated to the key,  `var.inbound_rules["${element(keys(var.inbound_rules), count.index)}"]`

To retrive the first element of the array, `element(var.inbound_rules["${element(keys(var.inbound_rules), count.index)}"], 0)`

The second element, `element(var.inbound_rules["${element(keys(var.inbound_rules), count.index)}"], 1)`, etc...

    direction                   = "Inbound" or "outbound"

Quite obvious, isn't it ? This is the only difference between inbound_rules and outbound_rules

    priority                    = "${100 + element(var.inbound_rules["${element(keys(var.inbound_rules), count.index)}"],0) * 10}"

The minimal value is 100. Each priority is multiplied by ten so as to have buffer to manually add intermediary rules
So, for an input 1, we generate 100 * 1*10=110, for an input 2, 120, etc...


    access                      = "${element(var.inbound_rules["${element(keys(var.inbound_rules), count.index)}"], 1)}"
    source_address_prefix       = "${element(var.inbound_rules["${element(keys(var.inbound_rules), count.index)}"], 2)}"
    source_port_range           = "${element(var.inbound_rules["${element(keys(var.inbound_rules), count.index)}"], 3)}"
    destination_address_prefix  = "${element(var.inbound_rules["${element(keys(var.inbound_rules), count.index)}"], 4)}"
    destination_port_range      = "${element(var.inbound_rules["${element(keys(var.inbound_rules), count.index)}"], 5)}"
    protocol                    = "${element(var.inbound_rules["${element(keys(var.inbound_rules), count.index)}"], 6)}"

Reads the array passed as input. This may have to be modified if the array structure is modified so as to respect the indexes. 

