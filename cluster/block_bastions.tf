#  Configuration of the kubelet service 
module "kubelet_bastion" {
    source                  = "./modules/ignition/kubelet"
    
    name                    = "bastion"
    hyperkube_image                = "${local.images["hyperkube"]}"
    pause_image             = "${local.images["pause"]}"
    dns_address             = "${local.dns_address}"
    schedule                = "false"
    cloud_provider          = "${var.cloud_provider}"
    noproxy                 = "${local.net_cidr},${local.registry_ip},${local.master_loadbalancer},${local.proxy_loadbalancer}"
    http_proxy              = "${local.proxy_loadbalancer}"
}

module "bastion_ip" {
    source                  = "./modules/azure/publicip"
    name                    = "bastion"
    resourcegroup           = "${module.base.cluster_name}"
    location                = "${var.location}"
}

# Aggregation of the ignition scripts
data "ignition_config" "bastion" {
    systemd = [
        "${module.docker.docker_logrotate_id}",
        "${module.kubelet_bastion.kubelet_id}",
        "${module.kubectl.kubectl_id}"
    ]

    files = [
        "${module.docker.docker_authent_id}",
        "${module.kubectl.alias_id}",
        "${module.kubeconfig_node.kubeconfig_id}",
        "${module.base.cloud_config_id}",
        "${module.tls.ca_ignition_id}",
        "${module.tls.client_cert_id}",
        "${module.tls.client_key_id}"
    ]

    directories = [
        "${data.ignition_directory.empty_manifest_dir.id}"
    ]
}

module "bastion" {
    source                  = "./modules/azure/block"

    name                    = "bastion"
    resourcegroup           = "${module.base.cluster_name}"
    location                = "${var.location}"
    #subnet_id               = "${module.base.subnet_id}"
    network_name            = "${module.base.network_name}"

    # Subnet
    cidr                    = "${local.bastion_cidr}"
    pod_cidr                = "${local.bastion_pod_cidr}"
    routetable              = "${module.base.routetable_id}"
    routetable_name         = "${module.base.routetable_name}"

    # Firewall rules
            

    "inbound_rules"         = "${merge(local.generic_inbound, local.bastion_inbound)}"
    "outbound_rules"        = "${merge(local.generic_outbound, local.bastion_outbound)}"

    # Load balancing
    type                    = "public"
    public_ip               = "${module.bastion_ip.ip_id}"
    "lb_port" {
        ssh             = ["22", "Tcp", "22"]
        kubectl         = ["443", "Tcp", "443"]
    }
    
    # VM
    count                   = "${var.bastion_count}" 
    coreos_version          = "${var.coreos_version}"
    size                    = "${var.bastion_size}"
    disk_type               = "${var.bastion_disk_type}"
    boot_user               = "${var.boot_user}"
    pub_key                 = "${file("${path.root}/ssh/insecure-deployer.pub")}"
    
    # Ignition provisionning
    ignition_tmpl           = "${data.ignition_config.bastion.rendered}"    
}
