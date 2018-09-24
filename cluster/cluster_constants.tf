locals {

	# CIDR

	# Overall network CIDR (and subnet)
        net_cidr                	= "10.0.0.0/8" 

	# CIDR for clusterIPs ie k8s services
        cluster_cidr            	= "10.0.0.0/16"
	pod_cidr                	= "10.192.0.0/11"
        vm_cidr                 	= "10.96.0.0/11"

	# Each VM will be like 10.100.x.1
        bastion_cidr            	= "10.100.0.0/16"
	bastion_pod_cidr		= "10.200.0.0/16"

	master_cidr             	= "10.101.0.0/16"
	master_pod_cidr			= "10.201.0.0/16"
	master_loadbalancer             = "10.101.95.1"

        worker_cidr             	= "10.102.0.0/16"
	worker_pod_cidr			= "10.202.0.0/16"

        storekeeper_cidr        	= "10.103.0.0/16"
	storekeeper_pod_cidr		= "10.203.0.0/16"

        proxy_cidr             		= "10.104.0.0/16"
	proxy_pod_cidr			= "10.204.0.0/16"
	proxy_loadbalancer             	= "10.104.95.1"

        ingress_cidr            	= "10.105.0.0/16"
	ingress_pod_cidr		= "10.205.0.0/16"

        data_net_cidr                   = "192.168.0.0/24"
        
	# Adress of the kube-dns service (to match the dns deployment manifest)
        dns_address             	= "10.0.0.10"

	# Artifactiry
        registry_ip             	= "13.73.165.134"


	# Images for provisioned assets
        images {
                hyperkube       	= "docker.bsm.utility.valapp.com/kubernetes/hyperkube:v1.8.7"
                etcd            	= "docker.bsm.utility.valapp.com/kubernetes/etcd:v3.2"
                squid           	= "docker.bsm.utility.valapp.com/kubernetes/squid-egress-controller:3.3.8-31"
                pause           	= "docker.bsm.utility.valapp.com/kubernetes/pause-amd64:3.0"
        }
}

# pre-init of the master hostnames to be passed to tls certificates for etcd
data "null_data_source" "etcd_cluster" {
  count                                 = "${var.master_count}"
  inputs = {
        hostnames                       = "master${count.index + 1}"
  }
}


