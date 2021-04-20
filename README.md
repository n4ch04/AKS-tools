# AKS Tools

I would like to share here a few tips and tiny tools that I have been generated during a project with AKS (Azure Kubernetes Service).  
We have used k8s not because we really need to use all the features the technology offers, but to learn and to enter in Kubernetes world.  

When you decide to use a managed kubernetes service, first thing you should know is that Azure, in this case but the other cloud providers are likely to do the same,  does not charge for control plane. What it has cost is worker node computing power, hard drives of the nodes, load balancers, storage accounts ...  

Then it's very important the choice of VM's type, and know how to fit your needs. In our case apps are ligth and do not consume a lot of resources, so we chose one of the cheapest. And here start the tricks, Azure, using web interface, assigns by default 128GB SSD premium as node disks, and it can't be changed, also sets premium load balancer to access the cluster. To change this is preferable to use azure cli.  
For us this is the cheapest cluster we could set it up:  

`az aks create -n XXXXX --resource-group XXXXXXX --node-count 3 --node-vm-size Standard_B2s --load-balancer-sku basic --node-osdisk-size 32 --attach-acr XXXXXXX`  

Connected to an ACR (Azure Container Registry) to deploy the apps once containers have been generated from DevOps repositories.  
Microsoft support indicates that at least node vm's must have 4GB of memory for the cluster to work correctly.  

Now we have our cluster running we can think about saving money, and powering it off when is not in use. As far as we know there are two alternatives:

- use `az aks start/stop` commands (az cli extension) which I don't recommend since it deleted resources of our cluster and complete crashed it (only Azure knows how)
- start/stop the set of vm's that make up worker nodes  

To start/stop the cluster and check its state I have included a very simple scripts that you can use with az cli configured.  

## k8s user management
Kubernetes does not have a resource for user management. Instead of accepts as user something signed with k8s cluster CA and interprets as username the content of CN field and as group the content of organisation field of the X509 certificate format. 
In your cluster you can use default roles of k8s to manage your users, which are:  
- view: read-only access, excludes secrets
- edit: view capabilities + ability to edit most resources, excluding roles and role bindings
- admin: edit capabilities + ability to manage roles and role bindings at namespace level
- cluster-admin: whatever you want

To use those roles you have to bind to an entity (like a group) via roleBinding and then create the user referring that binding.  
With role bindings created is time to create users. User creation is divided in the following steps:  
- Create user's key and CSR(certificate signing request) with openssl
- Format the CSR from openssl to be uploaded to the cluster
- Create the CSR as k8s resource in the cluster
- Approve the CSR in the cluster and download the certificate
- Generate kubeconfig file including the key, signed certificate, username, group and context

All these steps are summarized in the user creation script create-user.sh.  
To create the users execute it providing all input params (path to Cluster CA cert is optional, but it is going to create the file if you dont provide it), if dont, it is going to fail. 

## Postgres issues

Using postgres as backend database we face the problem of database data persistence. If you want to share a volume with database pod/s to store data (/var/lib/postgresql/data by default and its contents) and try with azureFile resources you will find:  

- Permission problems: you cannot mount the volume using same path as pod data folder.  
- Data persistence problems: Once you have solved the above you'll find that only the folder is mapped into the shared volume, but not its contents. If you kill the pod, all data of db is lost. We also tried to upload a file directly to the shared volume and check its existance through pod filesystem (and vice versa) and it was not accessible.  

We finally solve this creating a custom storageClass to use azure standard hdd's instead of ssd's (which have created by default storage classes in AKS) and pointing as storage directory in postgres via PGDATA env variable a folder out of /var/lib/postgresql/data path.  
This finally resolves the issue and data is still there when you kill the pod.  

```
kind: StorageClass
apiVersion: storage.k8s.io/v1
metadata:
  name: azuredisk-custom-storageclass
provisioner: kubernetes.io/azure-disk
reclaimPolicy: Delete
volumeBindingMode: WaitForFirstConsumer
parameters:
  storageaccounttype: Standard_LRS
---
apiVersion: v1
kind: PersistentVolumeClaim
metadata:
  name: database-pvc
spec:
  accessModes:
    - ReadWriteOnce
  storageClassName: "azuredisk-custom-storageclass"
  resources:
    requests:
      storage: 1Gi
---
    - name: PGDATA
              value: /var/lib/postgresql/backup
 
        volumeMounts:
          - name: database
            mountPath: /var/lib/postgresql
            subPath: backup
      
      volumes:
        - name: database
          persistentVolumeClaim:
            claimName: database-pvc
```
