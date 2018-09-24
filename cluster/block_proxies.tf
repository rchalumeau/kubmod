#  Configuration of the kubelet service
module "kubelet_proxy" {
        source                  = "./modules/ignition/kubelet"

        name                    = "proxy"
        hyperkube_image         = "${local.images["hyperkube"]}"
        pause_image             = "${local.images["pause"]}"
        dns_address             = "${local.dns_address}"
        schedule                = "false"
        cloud_provider          = "${var.cloud_provider}"
}


# Configuration of squid manifest
module "squid" {
	source                  = "./modules/ignition/squid"
	squid_image		= "${local.images["squid"]}"
}

data "ignition_config" "proxy" {

  systemd = [
        "${module.docker.docker_logrotate_id}",
	"${module.kubelet_proxy.kubelet_id}"
  ]

  files = [
    "${module.docker.docker_authent_id}",
    "${module.tls.ca_ignition_id}",
    "${module.tls.client_cert_id}",
    "${module.tls.client_key_id}",
    "${module.base.cloud_config_id}",
    "${module.kubeconfig_node.kubeconfig_id}",
    "${module.squid.whitelist_id}",
    "${module.squid.squid_id}"
  ]
}

module "proxy" {
	source                  	= "./modules/azure/block"

	name				= "proxy"
	resourcegroup			= "${module.base.cluster_name}"
	location			= "${var.location}"
        #subnet_id               	= "${module.base.subnet_id}"
        network_name            	= "${module.base.network_name}"


	# Subnet
	cidr				= "${local.proxy_cidr}"
	pod_cidr			= "${local.proxy_pod_cidr}"
        routetable              	= "${module.base.routetable_id}"
        routetable_name         	= "${module.base.routetable_name}"

	# Firewall rules
        inbound_rules                   = "${merge(local.generic_inbound, local.proxy_inbound)}"
        outbound_rules                  = "${merge(local.generic_outbound, local.proxy_outbound)}"
	
	# Load balancing
	type				= "private"
	loadbalancer_private_ip         = "${local.proxy_loadbalancer}"
        "lb_port" {
                squid                   = ["3128", "Tcp", "3128"]
        }
	
	# VM
	count 				= "${var.proxy_count}"
        coreos_version                  = "${var.coreos_version}"
	size				= "${var.proxy_size}"
	disk_type			= "${var.proxy_disk_type}"
	boot_user       		= "${var.boot_user}"
	pub_key         		= "${file("${path.root}/ssh/insecure-deployer.pub")}"
	
	# Ignition provisionning
	ignition_tmpl        		= "${data.ignition_config.proxy.rendered}"
	
}
