### k8s-user-management

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

