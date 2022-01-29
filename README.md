# minikube-web-server

minikube-web-server is a web server written in Flask and deployed in minikube, exposed to the clients using kubernetes ingress object


## Usage instructions

- Clone the repo
- Execute the `build-and-deploy.sh` script in this repo as a root user (Need root/sudo access to update /etc/hosts file to resolve the hostname)
- Access `local.ecosia.org/tree` in the browser once the script execution is complete

## Pre-requisites
- root/privileged access to update /etc/hosts file when executing the `build-and-deploy.sh` script
- Python version >= 3.7
- Docker version >= 20.0.0
- Minikube version >= 1.20 and in running status. Refer [Minikube installation](https://minikube.sigs.k8s.io/docs/start/)
- Kubectl version >= 1.20
- Ingress addons enabled in minikube
```
➜  $ minikube addons enable ingress
    ▪ Using image k8s.gcr.io/ingress-nginx/controller:v1.1.0
🔎  Verifying ingress addon...
🌟  The 'ingress' addon is enabled

➜  $ minikube addons enable ingress-dns
    ▪ Using image gcr.io/k8s-minikube/minikube-ingress-dns:0.0.2
🌟  The 'ingress-dns' addon is enabled
```



## Components
This project consists of 4 pieces - web server, dockerfile, minikube, kubernetes objects and a build-and-deploy.sh script to automate everything from the start.

#### 1. Web server
The Web server is written using Python's Flask web framework. It is a very minimal server which returns the json response of my favorite tree upon request to /tree path.

File: [app.py](https://github.com/kannan-ak/minikube-web-server/blob/main/app.py)


```python
@app.route('/tree', methods=["GET"])
def tree():
    response = {"myFavouriteTree": "Avocado"}
    return json.dumps(response)
```
`Usage: python3 -m flask run --host=0.0.0.0 --port=8080`

##### Test case

Test case involves Pytest module which queries the webserver and validate whether the server returns status code 200 and response as expected.

File: [test_app.py](https://github.com/kannan-ak/minikube-web-server/blob/main/test_app.py)

```python
def test_app():
    response = app.test_client().get('/tree')

    assert response.status_code == 200
    assert response.data == b'{"myFavouriteTree": "Avocado"}'
```

`Usage: python3 -m pytest`


#### 2. Dockerfile
Dockerfile contains instructions to copy the python files to a working directory and run pytest. Once the pytest is completed successfully, the image will be built with `cmd` to run flask app upon image execution.

File: [dockerfile](https://github.com/kannan-ak/minikube-web-server/blob/main/dockerfile)
```dockerfile
FROM python:3.8-slim-buster
WORKDIR /app
COPY app.py test_app.py requirements.txt /app
RUN pip3 install -r requirements.txt
RUN python3 -m pytest
CMD [ "python3", "-m" , "flask", "run", "--host=0.0.0.0", "--port=8080"]
```
`Usage: docker build -t webapp-image:v1 .`

#### 3. Minikube
This project requires a running minikube with ingress addons enabled. Once the image is created using docker build, the bash script will load the image into minikube.


#### 4. Kubernetes manifests files

- Deployment file to deploy the python web server as a replicaset with resource limits, security contexts
- Service file to expose the pods with a load balancer
- Ingress file to route requests to the webserver only on a given uri

Path: [K8s files](https://github.com/kannan-ak/minikube-web-server/tree/main/k8-manifests)

#

### build-and-deploy.sh script
This script has 3 phases of execution
- Phase 1: Creates docker build and loads the image into minikube
- Phase 2: Creates a deploymentset, service and ingress in minikube
- Phase 3: Updates the /etc/hosts file with minikube ip to resolve the hostname given in ingress rules
          and curl the ingress url

File: [build-and-deploy.sh](https://github.com/kannan-ak/minikube-web-server/blob/main/build-and-deploy.sh)

---

### Common errors and troubleshooting steps

1. Address not allocated to ingress and ingress creation fails
> 🤦 StartHost failed, but will try again: creating host: create: Error creating machine: Error in driver during machine creation: IP address never found in dhcp leases file Temporary error: could not find an IP address for 86:24:9f:1e:ce:99

**Cause**: Ingress addon is not enabled in minikube. 

**Fix**: Enable ingress using `minikube addons enable ingress` command



2. curl request to the url fails / ingress doesn't have IP address allocated 

> + curl local.ecosia.org/tree
> curl: (7) Failed to connect to local.ecosia.org port 80: Connection refused

**Cause and fix**: 

Check the ingress status

```bash
$ kubectl get ingress
NAME             CLASS   HOSTS              ADDRESS     PORTS   AGE
webapp-ingress   nginx   local.ecosia.org      			80      95s

$ kubectl describe ingress webapp-ingress
Default backend:  default-http-backend:80 (<error: endpoints "default-http-backend" not found>)

```

If the address field is empty, then the ingress is not working and most likely ingress addon is not enabled.
So refer the pre-requisites field and ensure ingress addons are enabled.


#

3. Ingress not working in mac os

**Cause**: Known issue. Ingress addon is not supported in MacOs for Docker driver. 

> The ingress, and ingress-dns addons are currently only supported on Linux. See #7332


**References**: 
- [Github issue link](https://github.com/kubernetes/minikube/issues/7332)
- [Docker driver documentation](https://github.com/kubernetes/minikube/issues/7332)

**Fix**: Run minikube with hyperkit driver 

```bash
$ brew install hyperkit
$ minikube start --driver=hyperkit
```

5. Hostname in ingress rule not accessible, nslookup fails
```
nslookup local.ecosia.org $(minikube ip)
>> ;; connection timed out; no servers could be reached
```
**Cause and fix**: Same as above point 3. This issue is specific to macos docker driver. Using hyperkit as a driver for minikube fixes this issue.

#
6. Requests are not routed to the ingress host's path

Ingress is working fine but requests to the local.ecosia.org/tree not returning expected response, throws 404 error.

As per the logs, the requests are not going to the api /tree. 

**Cause**: 
Issue is with the ingress configuration. 
Below annotation rewrite the requests to / path.
```
  annotations:
    nginx.ingress.kubernetes.io/rewrite-target: /
```
**Fix**: 
Removing the above annotation routes the requests accordingly and /tree returns expected response.

---
### Magic commands to use when nothing works in minikube
```
minikube stop 
minikube delete
minikube start
```
And start from the scratch again 😄 
