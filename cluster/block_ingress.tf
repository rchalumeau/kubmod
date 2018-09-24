#  Configuration of the kubelet service
module "kubelet_ingress" {
        source                  = "./modules/ignition/kubelet"

        name                    = "ingress"
        hyperkube_image         = "${local.images["hyperkube"]}"
        pause_image             = "${local.images["pause"]}"
        dns_address             = "${local.dns_address}"
        schedule                = "false"
        cloud_provider          = "${var.cloud_provider}"
        noproxy                 = "${local.net_cidr},${local.registry_ip},${local.master_loadbalancer},${local.proxy_loadbalancer}"
        http_proxy              = "${local.proxy_loadbalancer}"
}

data "ignition_config" "ingress" {

  systemd = [
       	"${module.docker.docker_logrotate_id}",
       	"${module.kubelet_ingress.kubelet_id}"
  ]

  files = [
    	"${module.docker.docker_authent_id}",
   	"${module.kubeconfig_node.kubeconfig_id}",
    	"${module.tls.ca_ignition_id}",
    	"${module.base.cloud_config_id}",
    	"${module.tls.client_cert_id}",
    	"${module.tls.client_key_id}"
  ]

  directories = [
    "${data.ignition_directory.empty_manifest_dir.id}"
  ]
}

module "ingress_ip" {
	source                	= "./modules/azure/publicip"
	name			= "ingress"
	resourcegroup		= "${module.base.cluster_name}"
	location		= "${var.location}"
}

module "ingress" {
  source                = "./modules/azure/block"

  name                  = "ingress"
  resourcegroup         = "${module.base.cluster_name}"
  location              = "${var.location}"
  #subnet_id               = "${module.base.subnet_id}"
  network_name            = "${module.base.network_name}"


  # Subnet
  cidr                  = "${local.ingress_cidr}"
  pod_cidr		= "${local.ingress_pod_cidr}"	
  routetable              = "${module.base.routetable_id}"
        routetable_name         = "${module.base.routetable_name}"

  # Firewall rules        
        inbound_rules                   = "${merge(local.generic_inbound, local.ingress_inbound)}"
        outbound_rules                  = "${merge(local.generic_outbound, local.ingress_outbound)}"
 
  
  # Load balamcing
  type                  = "public"
  public_ip		= "${module.ingress_ip.ip_id}"

    "lb_port" {
      http              = ["80", "Tcp", "30080"]
      https             = ["443", "Tcp", "30443"]
    }
  
  # VM
  count                 = "${var.ingress_count}"
  coreos_version        = "${var.coreos_version}"
  size                  = "${var.ingress_size}"
  disk_type             = "${var.ingress_disk_type}"
  boot_user             = "${var.boot_user}"
  pub_key               = "${file("${path.root}/ssh/insecure-deployer.pub")}"
  
  # Ignition provisionning
  ignition_tmpl              = "${data.ignition_config.ingress.rendered}"
}
