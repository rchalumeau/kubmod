# Install Kubectl Client

The module `ignition/kubectl` allows to install the binary kubectl and to create the aliases `kl` and `ks`. 

## Extract_kubectl service

A systemd one shot service is generated to extract the `kubectl` binary from the hyperkube docker image already present in all the VMs. It allows to have the kubectl version synchronised with the kubernetes server (hyperkube), without having to store it separately. 

It generates an ingition systemd to be passed to the bastion machines. It will install kubectl in /opt/bin which is already in PATH env var in coreOS.  

## Aliases

An ingition file allow to create and store in `/etc/profile.d` the following aliases : 
 - kl : `kubectl --kubeconfig=[api server credentials]`, it is the kubectl command for default namespace 
 - ks : `kubectl --kubeconfig=[api server credentials] -n kube-system`, kubectl command for kube-system namespace
 
 