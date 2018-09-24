# Genration of the tls certificates
module "tls" {
  source                = "./modules/tls2"
  bastion               = "${module.bastion_ip.ip}"
  internal_loadbalancer = "${local.master_loadbalancer}"
  etcd_cluster          = "${join(",", data.null_data_source.etcd_cluster.*.inputs.hostnames)},localhost"
}

#  Configuration of the kubelet service
module "kubelet_master" {
	source 			= "./modules/ignition/kubelet"

        name                    = "master"
        hyperkube_image         = "${local.images["hyperkube"]}"
        pause_image             = "${local.images["pause"]}"
        dns_address             = "${local.dns_address}"
        schedule                = "false"
        cloud_provider          = "${var.cloud_provider}"
        noproxy                 = "${local.net_cidr},${local.registry_ip},${local.master_loadbalancer},${local.proxy_loadbalancer}"
	http_proxy		= "${local.proxy_loadbalancer}"

}

# Configuration of the kubeconfig
module "kubeconfig_master" {
        source                  = "./modules/ignition/kubeconfig"
        name                    = "master"
}

# Configration of the core manifests
module "manifests" {
        source                  = "./modules/ignition/manifests"
        hyperkube_image         = "${local.images["hyperkube"]}"
	proxy			= "${local.proxy_loadbalancer}"
	cluster_cidr		= "${local.cluster_cidr}"
	pod_cidr		= "${local.pod_cidr}"
}

# Creation of the data dir for etcd and etcd services
data "ignition_directory" "opt_etcd_data_dir" {
    filesystem  = "root"
    path        = "/opt/etcd/data"
}

data "ignition_directory" "empty_manifest_dir" {
    filesystem  = "root"
    path        = "/etc/kubernetes/manifests"
    mode	= 0755
}

# FIXME : This module will generate a template with hostname variable
# It will be filled by the module master_block to set the right hostname
# Thios comes from a limitation of azure that does not provide hostname with coreos metadata
module "etcd" {
        source                  = "./modules/ignition/etcd"
	master_count		= "${var.master_count}"
        etcd_image         	= "${local.images["etcd"]}"
        cluster_name	        = "${module.base.cluster_name}"
}

# Agregation of the ignition scripts
data "ignition_config" "master" {

  systemd = [
        "${module.docker.docker_logrotate_id}",
	"${module.etcd.etcd_id}",
        "${module.kubelet_master.kubelet_id}",
        "${module.kubectl.kubectl_id}"

	
  ]

  files = [
    	"${module.docker.docker_authent_id}",
	"${module.tls.ca_ignition_id}",
        "${module.tls.apiserver_cert_id}",
        "${module.tls.apiserver_key_id}",
        "${module.tls.etcd_cert_id}",
        "${module.tls.etcd_key_id}",
    	"${module.base.cloud_config_id}",
        "${module.manifests.apiserver_id}",
        "${module.manifests.scheduler_id}",
        "${module.manifests.controller_id}",
    	"${module.kubeconfig_master.kubeconfig_id}"
  ]

    directories = [
        	"${data.ignition_directory.opt_etcd_data_dir.id}"
    ]
}

# Master block, includes subnet, vms, loadbalncer and firewall rules
module "master" {
	source                  	= "./modules/azure/block"

	name				= "master"
	resourcegroup			= "${module.base.cluster_name}"
	location			= "${var.location}"
        #subnet_id               	= "${module.base.subnet_id}"
        network_name            	= "${module.base.network_name}"

	# Subnet
	cidr				= "${local.master_cidr}"
	pod_cidr			= "${local.master_pod_cidr}"
        routetable              	= "${module.base.routetable_id}"
        routetable_name         	= "${module.base.routetable_name}"

	# Firewall rules	
        inbound_rules	 		= "${merge(local.generic_inbound, local.master_inbound)}"
	outbound_rules			= "${merge(local.generic_outbound, local.master_outbound)}"

	# Load balamcing
	type				= "private"
	loadbalancer_private_ip         = "${local.master_loadbalancer}"
	"lb_port" {
		api             	= ["443", "Tcp", "443", "8080"]
  	}
	
	# VM
	count 				= "${var.master_count}"
        coreos_version                  = "${var.coreos_version}"
	size				= "${var.master_size}"
	disk_type			= "${var.master_disk_type}"

	boot_user       		= "${var.boot_user}"
	pub_key         		= "${file("${path.root}/ssh/insecure-deployer.pub")}"
	
	# Ignition provisionning
	ignition_tmpl        		= "${data.ignition_config.master.rendered}"
	
}
