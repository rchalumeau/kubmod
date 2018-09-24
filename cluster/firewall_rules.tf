locals {
  generic_inbound = {
    "ssh-from_bastion" = [90, "Allow", "${local.bastion_cidr}", "*", "${local.vm_cidr}", "22", "Tcp"]

    /* Workaround for terraform before version 0.11.2 which does not accept list of port values */
    "kubelet-from-master1" = [91, "Allow", "${local.master_cidr}", "*", "${local.vm_cidr}", "10250", "Tcp"]
    "kubelet-from-master2" = [92, "Allow", "${local.master_cidr}", "*", "${local.vm_cidr}", "10255", "Tcp"]
  }

  generic_outbound = {
    to-infra-proxy = [90, "Allow", "${local.vm_cidr}", "*", "${local.proxy_cidr}", "3128", "Tcp"]
    to-apiserver   = [91, "Allow", "${local.vm_cidr}", "*", "${local.master_cidr}", "443", "Tcp"]
    to-ntp         = [92, "Allow", "${local.vm_cidr}", "*", "Internet", "123", "Tcp"]
    to-cockpit     = [95, "Allow", "${local.vm_cidr}", "*", "${local.registry_ip}", "443", "Tcp"]
    to-dns-tcp     = [96, "Allow", "${local.pod_cidr}", "*", "${local.master_pod_cidr}", "53", "Tcp"]
    to-dns-udp     = [97, "Allow", "${local.pod_cidr}", "*", "${local.master_pod_cidr}", "53", "Udp"]
    deny-outbound  = [100, "Deny", "${local.vm_cidr}", "*", "*", "*", "Tcp"]
  }

  bastion_inbound = {
    ssh-to-bastion     = [1, "Allow", "*", "*", "${local.bastion_cidr}", "22", "Tcp"]
    kubectl-to-bastion = [2, "Allow", "*", "*", "${local.bastion_cidr}", "443", "Tcp"]
  }

  bastion_outbound = {
    bastion-to-vm = [1, "Allow", "${local.bastion_cidr}", "*", "${local.vm_cidr}", "22", "Tcp"]
  }

  # Masters rules : masters apiserver are to be accessed by all vms (covered by generic inbound) and pod dns by all cluster pods
  master_inbound = {
    dns-tcp = [1, "Allow", "${local.pod_cidr}", "*", "${local.master_pod_cidr}", "53", "Tcp"]
    dns-udp = [2, "Allow", "${local.pod_cidr}", "*", "${local.master_pod_cidr}", "53", "Udp"]
  }

  master_outbound = {
    /* Workaround for terraform before version 0.11.2 which does not accept list of port values */
    master-to-nodes1 = [1, "Allow", "${local.master_cidr}", "*", "${local.vm_cidr}", "10250", "Tcp"]
    master-to-nodes2 = [2, "Allow", "${local.master_cidr}", "*", "${local.vm_cidr}", "10255", "Tcp"]
    master-to-pods   = [3, "Allow", "${local.master_cidr}", "*", "${local.pod_cidr}", "8000-9000", "Tcp"]
    to-k8s-services  = [98, "Allow", "${local.master_cidr}", "*", "${local.cluster_cidr}", "8000-9000", "Tcp"]
  }

  # Workers accept calls from ingress (front services in the range of 8000-9000
  worker_inbound = {
    from_ingress = [1, "Allow", "${local.ingress_pod_cidr}", "*", "${local.worker_pod_cidr}", "8000-9000", "Tcp"]
  }

  worker_outbound = {
    to_proxy         = [1, "Allow", "${local.worker_pod_cidr}", "*", "${local.proxy_pod_cidr}", "3128", "Tcp"]
    to-apple         = [2, "Allow", "${local.worker_cidr}", "*", "17.0.0.0/8", "443", "Tcp"]
    to-data-net      = [11, "Allow", "${local.worker_cidr}", "*", "${local.data_net_cidr}", "1521", "*"]
    to-azure-storage = [12, "Allow", "${local.worker_cidr}", "*", "Storage", "445", "Tcp"]
    to-k8s-services  = [98, "Allow", "${local.worker_cidr}", "*", "${local.cluster_cidr}", "8000-9000", "Tcp"]
  }

  # Ingress controllers are accessed by node ports
  ingress_inbound = {
    lb-https   = [1, "Allow", "*", "*", "AzureLoadBalancer", "443", "Tcp"]
    node-https = [2, "Allow", "Internet", "*", "${local.ingress_cidr}", "30443", "Tcp"]
    lb-http    = [3, "Allow", "*", "*", "AzureLoadBalancer", "80", "Tcp"]
    node-http  = [4, "Allow", "Internet", "*", "${local.ingress_cidr}", "30080", "Tcp"]
  }

  ingress_outbound = {
    to-worker = [1, "Allow", "${local.ingress_pod_cidr}", "*", "${local.worker_pod_cidr}", "8000-9000", "Tcp"]
  }

  proxy_inbound = {
    to-infra-proxy = [1, "Allow", "${local.vm_cidr}", "*", "${local.proxy_cidr}", "3128", "Tcp"]
    to-app-proxy   = [2, "Allow", "${local.worker_pod_cidr}", "*", "${local.proxy_pod_cidr}", "3128", "Tcp"]
  }

  proxy_outbound = {
    to-internet = [1, "Allow", "${local.proxy_cidr}", "*", "Internet", "443", "Tcp"]
    to-internet = [2, "Allow", "${local.proxy_cidr}", "*", "Internet", "80", "Tcp"]  # Required for Entrust CA CDN check
  }
}
