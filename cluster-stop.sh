#! /bin/bash


#stopped state of cluster
stopped="deallocated"

#current state of cluster
state=`az vmss show --resource-group XXXXXXXXX --name XXXXXXX --instance-id 0 --query instanceView.statuses[1].code | sed 's/.*\///; s/"//'`

#Stopping VMS
echo "Stopping Azure Virtual Machine Scale Set from cluster ...."
if [ ${state} == ${stopped} ]
then 
        echo "Cluster is already stopped"; 
else 
        echo "Cluster is running, powering off ...";
        az vmss deallocate --name XXXXXXX --resource-group XXXXXXXXX
        echo "Cluster stopped"
fi
