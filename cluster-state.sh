#! /bin/bash

# states of cluster
started="running"
stopped="deallocated"

#Current state of cluster
state=`az vmss show --resource-group MC_ciber-development-cloud_cloud-audit-cluster_francecentral --name aks-nodepool1-33573588-vmss --instance-id 0 --query instanceView.statuses[1].code | sed 's/.*\///; s/"//'`

#Starting VMS
echo "Checking cluster state ...."
if [ ${state} == ${started} ]
then 
	echo "Cluster is running"; 
elif [ ${state} == ${stopped} ]
then
	echo "Cluster is stopped";
else
	echo "Unknown and strange state";
fi
