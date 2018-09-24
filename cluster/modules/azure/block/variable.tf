
#### Global setting ####

variable "name" {
	description = "[Required] Name of the block (typically worker, master, proxy, etc...)"
}

variable "resourcegroup" {
	description = "[Required] name of the resource group to install the block on"
}
variable "location" {
	description = "[required] location of the installation. Typically the location of the resource group."
}

/*variable "subnet_id" {
        description = "[required] Name of the virtual network to attach the subnets to."
}
*/
variable "tags" {
	description = "[Optional] Tags to add to azure resources"
	default = {}
}

variable "network_name" {}


##### Firewall settings ####

variable "inbound_rules" {
	description = "[Optional] Protocols to be used for lb health probes and rules. name [access, sourceip, sourceport, destinationip, destinationport, protocol]"
	default     = {}
}

variable "outbound_rules" {
	description = "[Optional] Protocols to be used for lb health probes and rules. name [access, sourceip, sourceport, destinationip, destinationport, protocol]"
	default     = {}
}

#### Subnet settings ####

variable "cidr" {
	description = "[Required] CIDR of the subnet to create. Must be part of the Virtual networks CIDRs"
}

variable "pod_cidr" {
        description = "[Required] CIDR of the cidr booked for the pods on is block."
}

variable "routetable" {
	description = "[Required] ID of the user routes table."
}

variable "routetable_name" {
        description = "[Required] ID of the user routes table."
}


#### Load balancer settings ####
variable "type" {
	description = "[Optional] type of the load balancer. One of private, public, none. Default is none." 
	default = "none"
}

variable "lb_probe_unhealthy_threshold" {
  description = "Number of times the load balancer health probe has an unsuccessful attempt before considering the endpoint unhealthy."
  default     = 2
}

variable "lb_probe_interval" {
  description = "Interval in seconds the load balancer health probe rule does a check"
  default     = 5
}

variable "lb_port" {
  description = "Protocols to be used for lb health probes and rules. [frontend_port, protocol, backend_port]"
  default     = {}
}

# Variable eto set if private lb
variable "loadbalancer_private_ip" {
	description = "[Required if private LB] private IP of the load balancer"
	default = ""
}

variable "public_ip" {
	default = ""
}


#### VM settings ###
variable "count" {
	description = "[Optional] Number of virtual machines to provision. Default is 1"
	default = "1"
}

variable "size" {
	description = "[OPtional] size of the machine. Default is Standard_D2_v2"
	default = "Standard_D2_v2"
}

variable "disk_type" {
	description = "[optional] type of disk. Default Premium_LRS"
	default = "Premium_LRS"
}

variable "coreos_version" {
	description = "[optional] version of coreos to install. Default is latest"
	default = "latest"
}

variable "boot_user" {
	description = "user to be used by Azure to provision the machine. Default is custadm"
	default = "custadm"
}

variable "pub_key" {
	description = "Public key for boot user"
}

variable "ignition_tmpl" {
	description = "Ignition configuration to pass at machine bootstrap"
	default = ""
}
