#! /bin/bash

#Running state of cluster
started="running"

#Current state of cluster
state=`az vmss show --resource-group MC_ciber-development-cloud_cloud-audit-cluster_francecentral --name aks-nodepool1-33573588-vmss --instance-id 0 --query instanceView.statuses[1].code | sed 's/.*\///; s/"//'`

#Starting VMS
echo "Starting Azure Virtual Machine Scale Set from cluster ...."
if [ ${state} == ${started} ]
then 
	echo "Cluster is already started"; 
else 
	echo "Cluster is stoppped, powering on ...";
	az vmss start --name aks-nodepool1-33573588-vmss --resource-group MC_ciber-development-cloud_cloud-audit-cluster_francecentral
	echo "Cluster started"
fi
