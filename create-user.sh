#! /bin/bash

echo "K8s cloud audit cluster user creation"


# k8s user
user=$1
# k8s group
group=$2
# k8s namespace
namespace=$3
# k8s cluster ca path
cacert=$4

# Usage display
usage () {
	echo "This tool has to be used as cluster super administrator with kubectl configured, also openssl must be installed" 
	echo "Usage: create-user.sh <username> <group> <namespace> [<cluster ca path>]" 
}

# Print to k8s csr file
csr-print () {
	echo "${1}" >> ${user}-${namespace}-certs/${user}-${namespace}-csr.yaml
}

# Check input values
if [[ -z $1 || -z $2 || -z $3 ]]
then
	usage
else 
	# create directory for intermediate files
	mkdir ${user}-${namespace}-certs
	# generate key and csr
	echo "##### Generating user key and certificate signing request with openssl...."
	openssl req -new -newkey rsa:4096 -nodes -keyout ${user}-${namespace}-certs/${user}-${namespace}.key -out ${user}-${namespace}-certs/${user}-${namespace}.csr -subj "/CN=${user}/O=${group}"
	echo "##### Key ${user}-${namespace}.key and CSR ${user}-${namespace}.csr created"
        # generate csr to be signed by the cluster
	echo "##### Generating csr yaml file ..."
	csr-print "apiVersion: certificates.k8s.io/v1beta1"
	csr-print "kind: CertificateSigningRequest"
	csr-print "metadata:"
 	csr-print "    name: ${user}-${namespace}-csr"
	csr-print "spec:" 
  	csr-print "    groups:" 
  	csr-print "    - system:authenticated" 
  	csr-print "    request: $(cat ${user}-${namespace}-certs/${user}-${namespace}.csr | base64 | tr -d '\n')" 
  	csr-print "    usages:"
  	csr-print "    - client auth"
	echo "##### Create the csr in the cluster ..."
	kubectl apply -f ${user}-${namespace}-certs/${user}-${namespace}-csr.yaml
	echo "##### Check its state (must be appear as pending) ..."
	kubectl get csr | grep "NAME\|${user}-${namespace}"
	echo "##### Approving the csr ..."
	kubectl certificate approve ${user}-${namespace}-csr
	echo "##### Check its state ..."
	kubectl get csr | grep "NAME\|${user}-${namespace}"
	echo "##### Retrieving user certificate ..."
	kubectl get csr ${user}-${namespace}-csr -o jsonpath='{.status.certificate}' | base64 --decode > ${user}-${namespace}-certs/${user}-${namespace}-csr.crt
	echo "##### Deleting csr ..." 
	kubectl delete csr ${user}-${namespace}-csr
	# Check if ca path is provided, if not get ca cert from the cluster
	if [ -z $4 ]
	then
		echo "##### CA cert path not provided, extracting ca cert from kubectl config ..."
		kubectl config view -o jsonpath='{.clusters[0].cluster.certificate-authority-data}' --raw | base64 --decode - > ${user}-${namespace}-certs/kubernetes-ca.crt
		cacert="${user}-${namespace}-certs/kubernetes-ca.crt"
	fi
	# generating kubeconfig
	echo "##### Generating kubeconfig for user ${user} of group ${group} in namespace ${namespace} ..."
	kubectl config set-cluster $(kubectl config view -o jsonpath='{.clusters[0].name}') --server=$(kubectl config view -o jsonpath='{.clusters[0].cluster.server}') --certificate-authority=${cacert} --kubeconfig=${user}-${namespace}-kubeconfig.yaml --embed-certs
	# setting extra config in kubeconfig file
	echo "##### Setting credentials in kubeconfig ..."
	kubectl config set-credentials ${user} --client-certificate=${user}-${namespace}-certs/${user}-${namespace}-csr.crt --client-key=${user}-${namespace}-certs/${user}-${namespace}.key --embed-certs --kubeconfig=${user}-${namespace}-kubeconfig.yaml
	echo "##### Setting context in kubeconfig ..."
	kubectl config set-context ${user}-${namespace} --cluster=$(kubectl config view -o jsonpath='{.clusters[0].name}') --namespace=${namespace} --user=${user} --kubeconfig=${user}-${namespace}-kubeconfig.yaml
	echo "##### Switching context ..."
	kubectl config use-context ${user}-${namespace} --kubeconfig=${user}-${namespace}-kubeconfig.yaml
	echo "##### User created"

fi

