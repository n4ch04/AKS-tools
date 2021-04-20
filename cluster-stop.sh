#! /bin/bash


#stopped state of cluster
stopped="deallocated"

#current state of cluster
state=`az vmss show --resource-group MC_ciber-development-cloud_cloud-audit-cluster_francecentral --name aks-nodepool1-33573588-vmss --instance-id 0 --query instanceView.statuses[1].code | sed 's/.*\///; s/"//'`

#Stopping VMS
echo "Stopping Azure Virtual Machine Scale Set from cluster ...."
if [ ${state} == ${stopped} ]
then 
        echo "Cluster is already stopped"; 
else 
        echo "Cluster is running, powering off ...";
        az vmss deallocate --name aks-nodepool1-33573588-vmss --resource-group MC_ciber-development-cloud_cloud-audit-cluster_francecentral
        echo "Cluster stopped"
fi
