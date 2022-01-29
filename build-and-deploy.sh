#!/bin/bash
## Usage: bash build-and-deploy.sh [or] ./build-and-deploy.sh
## Arguments: NA
## 
## 
## This script has 3 phases of execution
## Phase 1: Creates docker build and loads the image into minikube
## Phase 2: Creates a deploymentset, service and ingress in minikube
## Phase 3: Update the /etc/hosts file with minikube ip mapping hostname given in ingress
##          and curl the ingress url



set -euxo pipefail

echo "
###### Prerequisites ###### 
--> RUN THIS SCRIPT AS ROOT USER TO UPDATE /etc/hosts file
--> Docker and Minikube must be running
--> Ingress addons enabled 
--> Minikube driver supports ingress
--> docker, minikube, kubectl executable files are added to path variables
"


docker_build() {

echo "Building docker image"

docker build -t webserver-image:v1 .

echo "Docker image is built successfully!!!! 
Loading docker image to Minikube"

/usr/local/bin/minikube image load webserver-image:v1

}


k8s_deployment () {

	echo "Creating $1"

	/usr/local/bin/kubectl apply -f k8-manifests/$1.yml

	sleep 10s

}


update_hosts () {
	echo "Updating hosts file. This command requires ADMIN privileges."

	echo -e "$(/usr/local/bin/minikube ip)\t local.ecosia.org" | sudo tee -a /etc/hosts
}


main () {
	echo "##### Beginning Phase 1"
	echo "Calling docker_build function"
	docker_build

	echo "##### Beginning Phase 2"
	echo "Calling k8s_deployment function"

	k8s_deployment deployment
	k8s_deployment service
	k8s_deployment ingress

	echo "Deployments are completed. Sleep for a minute to ingress to come up"
	sleep 60s


	echo "##### Beginning Phase 3"
	update_hosts

	echo "Curl'ing Ingress endpoint"
	curl local.ecosia.org/tree 
	echo "WILLKOMMEN BEI ECOSIA ORG"
}

main
