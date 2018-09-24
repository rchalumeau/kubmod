#  Configuration of the kubelet service
module "kubelet_worker" {
        source                  = "./modules/ignition/kubelet"

        name                    = "worker"
        hyperkube_image         = "${local.images["hyperkube"]}"
        pause_image             = "${local.images["pause"]}"
        dns_address             = "${local.dns_address}"
        schedule                = "true"
        cloud_provider          = "${var.cloud_provider}"
        noproxy                 = "${local.net_cidr},${local.registry_ip},${local.master_loadbalancer},${local.proxy_loadbalancer}"
        http_proxy              = "${local.proxy_loadbalancer}"
}

data "ignition_config" "worker" {

  systemd = [
        "${module.docker.docker_logrotate_id}",
       "${module.kubelet_worker.kubelet_id}"
  ]

  files = [
    	"${module.docker.docker_authent_id}",
    	"${module.kubeconfig_node.kubeconfig_id}",
        "${module.tls.ca_ignition_id}",
        "${module.tls.client_cert_id}",
    	"${module.base.cloud_config_id}",
 	"${module.udev.udev_id}",
        "${module.tls.client_key_id}"
  ]

  directories = [
    "${data.ignition_directory.empty_manifest_dir.id}"
  ]
}

module "worker" {
        count                   	= "${ var.worker_count > 0 ? 1 : 0}"
	source                  	= "./modules/azure/block"

	name				= "worker"
	resourcegroup			= "${module.base.cluster_name}"
	location			= "${var.location}"
        #subnet_id               	= "${module.base.subnet_id}"
        network_name            = "${module.base.network_name}"

	# Subnet
	cidr				= "${local.worker_cidr}"
	pod_cidr			= "${local.worker_pod_cidr}"
        routetable              = "${module.base.routetable_id}"
        routetable_name         = "${module.base.routetable_name}"

	# Firewall rules	
        inbound_rules 			= "${merge(local.generic_inbound, local.worker_inbound)}"
	outbound_rules			= "${merge(local.generic_outbound, local.worker_outbound)}"
	
	# Load balamcing
	type				= "none"
	
	# VM
	count 				= "${var.worker_count}"
        coreos_version                  = "${var.coreos_version}"
	size				= "${var.worker_size}"
	disk_type			= "${var.worker_disk_type}"
	boot_user       		= "${var.boot_user}"
	pub_key         		= "${file("${path.root}/ssh/insecure-deployer.pub")}"
	
	# Ignition provisionning
	ignition_tmpl        		= "${data.ignition_config.worker.rendered}"
}
