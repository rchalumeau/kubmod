# Azure Base Module

This module is defined in modules/azure/base. 
It provisions the core assets of the cluster, ie, 
 - Resource group
 - Virtual Network (CIDR of which is defined in `cluster_constants.tf`)
 - User routes table (that will stores the network routes between the pods and the infra)
 - A subnet (the CIDR of which is defined in `cluster_constants.tf`)

It also prepare an ignition file configuring the azure configurations to be passed to the cluster. 

It uses a data.null_data_source to list the parameters : the `inputs`is actually a map, that is transformed in json through the `json_encode`. 

This json string is then passed to an ignition file (creating the /etc/kubernetes/azure.json) that is useable through the output cloud_config_id. 