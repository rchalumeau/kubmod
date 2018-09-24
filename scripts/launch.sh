#!/bin/sh


# instruction to pass, is plan, or refresh, or apply
COMMAND=$1

# The configuration file is mounted as /config
# So the instructions shall be run as 
#/terraform [instruction] -var-file=/config /cluster

# Retrieve the clustername from configuration file
cluster=$(grep cluster_name /config | cut -d '"' -f2)

if [ -z ${DEBUG+x} ]; then
echo "Using remote state (bsm)..."
# Prepare the remote state oin artifactory
cat<<EOF > /cluster/remote_state.tf
terraform {
  backend "artifactory" {
    username = "terraform"
    password = "AP2Q6vDDdDPS5tD3etCKbWAxkur"
    url      = "https://bsm.utility.valapp.com/artifactory"
    repo     = "terraform-states"
    subpath  = "${cluster}"
  }
}
EOF

# Rerun init to take the remote state into account
/bin/terraform init /cluster

else
echo "Using local state..."
fi

echo "Provisionning $cluster..."

/bin/terraform $COMMAND -var-file=/config -state=${cluster}.states $RESOURCE /cluster
