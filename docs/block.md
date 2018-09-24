# Block module

The Azure  block module allows to create in once the subnet, the Vms, the availability set, the firewall rules and the load balancing rules for a functional set of nodes. 
The code is located on modules/azure/block. 

It is generic enough for masters, workers, proxies, ingress and bastions. 

Here is how to instantiate a block : 

## Example

     1 module "ingress" {
     2  source                = "./modules/azure/block"
    
     3  name                  = "ingress"
     4  resourcegroup         = "${module.base.cluster_name}"
     5  location              = "${var.location}"

     6  # Subnet
     7  subnet_id             = "${module.base.subnet_id}"
     8  cidr                  = "${local.ingress_cidr}"
     9  pod_cidr              = "${local.ingress_pod_cidr}"
    10  routetable            = "${module.base.routetable}"
    
    11  # Firewall rules
    
    12  inbound_rules         = {
    13    ssh-from-bastion    = [1, "Allow", "${local.bastion_cidr}", "*", "${local.ingress_cidr}", "22",    "Tcp"]
    14    lb-https            = [2, "Allow", "*",                     "*", "AzureLoadBalancer",     "443",   "Tcp"]
    15    node-https          = [3, "Allow", "Internet",              "*", "${local.ingress_cidr}", "30443", "Tcp"]
    16    lb-http             = [4, "Allow", "*",                     "*", "AzureLoadBalancer",     "80",    "Tcp"]
    17    node-http           = [5, "Allow", "Internet",              "*", "${local.ingress_cidr}", "30080", "Tcp"]
    18    master-to-ingress   = [8, "Allow", "${local.master_cidr}",  "*", "${local.ingress_cidr}", "10250", "Tcp"]
    19  }
    20  "outbound_rules" {
    21    "ingress-to-ntp"    = [1, "Allow", "${local.ingress_cidr}", "*", "Internet",             "123",       "Tcp"]
    22    "ingress-to-worker" = [2, "Allow", "${local.ingress_cidr}", "*", "${local.worker_cidr}", "*", "Tcp"]
    23    "deny-internet"     = [3, "Deny",  "${local.worker_cidr}",  "*", "Internet",             "*",         "Tcp"]
    24  }
    
    25  # Load balamcing
    26  type                  = "public"
    27  public_ip             = "${module.ingress_ip.ip_id}"
    
    28    "lb_port" {
    29      http              = ["80", "Tcp", "30080"]
    30      https             = ["443", "Tcp", "30443"]
    31    }
    
    32  # VM
    33  count                 = "${var.ingress_count}"
    34  coreos_version        = "${var.coreos_version}"
    35  size                  = "${var.ingress_size}"
    36  disk_type             = "${var.ingress_disk_type}"
    37  boot_user             = "${var.boot_user}"
    38  pub_key               = "${file("${path.root}/ssh/insecure-deployer.pub")}"
    
    39  # Ignition provisionning
    40  ignition_tmpl              = "${data.ignition_config.ingress.rendered}"
    41}

## Instance of a module (lines 2-3)

All the blocks instantiates the same module. Therefore the name is required to differentiate the instances. This same name will be used as prefix of the generated assets. 
For instance, the load balancer of the worker name will be worker-lb.  

## Networking configuration (lines 6-10)

The lines 6 to 10 defines the parameters needed to correctly set the networking of both the Azure components (NIC, user routes) and the kubernes network (bridge and pods CIDR). 
The CIDR are defined in `cluster_constants.tf`. It is important to check that the IP ranges of VMs and Pods do not overlap. 

Refer to [networking doc](docs/networking.md) for deeper explanation. 

## Firewall rules (lines 11-24)

This part defines the inbound and outbound rules. It can contain VM and pods CIDR. The blocks are optional. If unset, the default rules from azure will apply, ie, no inbound and wide open outbound connections.   
Refer to [firewall doc](docs/nsg.md) for deeper explanation on how to configure the rules. 

## Load balancing (lines 25-31)

This part defines the load balancing rules. The type can be one of : 
- `public` : it creates an internet facing load balancer. In that case, the id of a public address must be set as `public_ip`
- `private` : it creates a load balancer in the subnet. It is only accessible from the vnet. A `private_ip` must be passed as parameter. 
- `none` : no balancer is created. 

The rules are defined in lb_ports with frontend port -> backend port. The probes are only Tcp probes. 

Refer to [load balancers doc](docs/lb.md) for deeper explanation

## VMs configuration (lines 32-40)

This part defines the VM configuration. The created VMs have an OS  managed disk. 

`count` parameter defines the number of expected VM in the availability set. 

`size` and `disk_type` define respectively the image type of the VM (CPU and memory) and the mounted disk (HDD or SSD). 

The size is in the form `Standard_D2s_v3`, the disk size in the form `Premium_LRS`. 
The disk type has to match the VM size. For instance, a `Premium_LRS` (SSD) can only be attached to a machine `s`type like the `Standard_D2s_v3`. A machine `Standard_D1_v2` will need to attach a disk `Standard_LRS` (HDD). 

You can refer to [Azure VM sizes](https://docs.microsoft.com/en-us/azure/virtual-machines/linux/sizes) for more up to date information. 

`coreos_version` is the version of the core OS from the channel `stable`. By default, it `latest`. This version is to exist in the azure library. 

`boot_user`and `pub_key` are the initial user account created to provision. The key is stored in ssh folder. 

Finally, the `ignition_tmpl` contains the ignition configuration to be launched by OS bootstrap (cf below). is to be passed the id of the ignition configuration. 

## Ignition 

Example: 

    data "ignition_config" "ingress" {
    
      systemd = [
            "${module.docker.docker_logrotate_id}",
            "${module.kubelet_ingress.kubelet_id}"
      ]
    
      files = [
            "${module.manifests.kubeproxy_id}",
            "${module.docker.docker_authent_id}",
            "${module.kubeconfig_node.kubeconfig_id}",
            "${module.tls.ca_ignition_id}",
            "${module.base.cloud_config_id}",
            "${module.tls.client_cert_id}",
            "${module.tls.client_key_id}"
      ]
    }

An ignition configuration gathers the ignition elements to be launched at bootstrap. 

An ignition configuration can contain : 
 - ignition_disk : to mount disks
 - ignition_file: to provision a file (for instance kubernetes manifests, docker authent, ...)
 - ignition_link: to provision links
 - ignition_directory : to create empty directory (for instance, data dir for etcd)
 - ignition_systemd_unit : to create, enable and launch a service (for instance kubelet and etcd services) 
 - ignition_user : to create a user
 - ignition_group : to create a group 

**The ID of the ignition resource os to be passed to ignition configuration.** 

For more info, refer to [terraform doc](https://www.terraform.io/docs/providers/ignition/index.html) 
 