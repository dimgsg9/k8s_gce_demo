# Kind of a doco

I assume if you follow these instructions attentively and I haven't messed up anything you should be able to achieve the following:

* Deploy Kubernetes cluster into the predefined GCP project and region.
* Setup Helm.
* Setup GitLab integration for CI/CD.
* Install and configure EFK (Elasticsearch, FluentD & Kibana) stack for log collection and visualisation.

## What you need before you start

1. Bash along with ability to execute bash commands on non-Windows machine :-)
1. `gcloud` CLI installed and configured of the latest version. Please add *alpha* and *beta* components to it.
1. `kubectl` CLIE installed and configured (of the latest version, as of now it's 1.15.1)
1. Ensure `cfssl` is installed. And most recent version of `openssl` is installed too. Ensure bash v > 4.x. For OSX install openssl with brew and make sure to export PATH.
1. Few more things that my `prerequisites.sh` script will check and if fails you may need to resolve the dependencies. I tried to make errors robust.

### Important notes

On Mac (OSX) even if openssl is installed (with `brew`) it doesn't link the binaries nor it adds PATH, might be workarounded like so:
`export PATH=/usr/local/opt/openssl/bin:$PATH`

`openssl version -a | head -n 1 | awk '{print $1}'` may return LibreSSL

Useful article regarding OpenSSL vs LibreSSL challenge in OSX:
https://medium.com/@timmykko/using-openssl-library-with-macos-sierra-7807cfd47892

And yeas, *md5sum* is not available in OSX by default, so better to resolve it like so:
`brew install md5sha1sum`

When deploying the cluster it will ask you for your SSH key passphrase many many time (a little annoying), so if has been set you will need to key in passphrase a number of times. Take it easy huh :)

While running `prerequisites.sh` script it will open your web browser and redirect to oauth2 GCP page. Don't be scared. It's not a scam.

Don't forget to include `kubectl` binaries to your PATH:

Example:
`export PATH=/Users/dmitry/Code/k8s_gce_demo/kubernetes/client/bin:$PATH`


To do: `ENABLE_PROMETHEUS_MONITORING="${KUBE_ENABLE_PROMETHEUS_MONITORING:-false}"` - descoped due to time constraint. Sorry :(

## Prerequisites and GCP project setup

Execute 

```
prerequisites.sh <YOUR_GCP_PROJECT_ID>
``` 

Script will perform the following:
1) Check what OS you're running.
2) Check your bash version compatibility with kubernetes installation scripts.
3) Whether `cfssl` is installed and PATH configured.
4) Check the presense of `openssl` and proper PATH to a right library (as mentioned earlier on Mac OSX it may point to LibreSSL).
5) Check if python 2.7 is installed and available.
6) Check if `gcloud` CLI is installed and available.
7) Check if all required `gcloud` components are installed (if not it will point you in the right direction).
8) If all checks pass, it asks if you want to proceed to download remaining installation scripts.
9) If you say "Y/Yes" it will download necessary installation scripts and dependencies from Kubernetes repositories and save it to folder `./kubernetes`
10) It will attempt to authenticate via your web browser (and your consent) to GCP in order to get token.
11) It will set project scopr and API permissions to manage GCE instance group APIs.

## Deploy cluster to a GCP region

Run the following script by specifying GCE region to deploy the VMs for cluster (please choose the region carefully, and in some cases there are strict quotas enforced by Google on the number of IPs and compute resources:

If you want to try and deploy multiple masters (requires more resources, please open the script and uncomment the lines as described inside the script):

```
deploy_cluster.sh <YOUR_GCP_REGION_ID>
```

### Setup Kubernetes Web UI (optinal)
`kubectl apply -f https://raw.githubusercontent.com/kubernetes/dashboard/v2.0.0-beta1/aio/deploy/recommended.yaml`

Then you can use `kubectl port-foward` to access it.

## Deploying apps in own namespace (manual mode)

P.S> CI/CD option is described separately.

Execute the following commands to get all required Kubernetes objects created:

Create namespace:
```
kubectl create -f example_guestbook/dev_namespace.yaml
```

Create redis service and master/slave deployments:
```
kubectl apply -f example_guestbook/redis-master-deployment.yaml --namespace=development

kubectl apply -f example_guestbook/redis-master-service.yaml --namespace=development

kubectl apply -f example_guestbook/redis-slave-deployment.yaml --namespace=development

kubectl apply -f example_guestbook/redis-slave-service.yaml --namespace=development
```

Deploy demo guestbook app (along with ingress for access over public IP or URL:
```
kubectl apply -f example_guestbook/frontend-deployment.yaml --namespace=development

kubectl apply -f example_guestbook/frontend-service.yaml --namespace=development

kubectl apply -f example_guestbook/frontend-ingress.yaml --namespace=development
```

It may take some time for GCP load balancer created by ingress controller to start sending traffic as it's a little slow to set backend destination (service) as healthy.

You can get public IP of the load balancer via GCP Console and configure any URL to point to this IP in your `hosts` file for further testing.

## Installing helm via autoinstaller (given I don't know what OS you're using)

Time for Helm:

Install Helm scripts on your machine:
`curl -L https://git.io/get_helm.sh | bash`

Configure custom role and bindings:
`kubectl apply -f helm_setup/rbac_setup.yaml`

Finally, install Helm server part (*tiler*) in isolated `development` namespace:
`helm init --service-account tiller --tiller-namespace development --history-max 200`

## Integrating GitLab CI/CD

### Prerequisites

Before you start using GitLab CI/CD pipeline for the demo application shared earlier in this docs, you need to first configure corresponding service account and custom role with role bindings in your Kubernetes cluster by executing the following command:
```
kubectl apply -f gitlab_setup/gitlab_admin_sa.yaml
```

### Register Kubernetes cluster in GitLab
In my case I registered Kubernetes cluster (make sure you also have account in docker hub to host public repository for application image).

Create Gitlab service account, custom role and corresponding roleBinding (all provided in previous step).

#### Important cluster settings in GitLab control panel:
1) Env scope: *
2) Base domain: ''
3) Don't install Gitlab managed applications
4) Set *Project namespace* as `development`
5) Select *RBAC-enabled cluster*
6) Select *GitLab-managed cluster*

### Docker registry account

You will need one to store docker image produced by GitLab CI build job.

### Configure CI/CD:

Please, refer further to corresponding README in [guestbook CI/CD pipeline repo](https://github.com/dimgsg9/gb-demo-k8s) 

## Settings EFK stack to collect and visualise pod logs

Just run the following commands to create all required objects in `kube-logging` namespaceh

`kubectl config set-context --current --namespace=kube-logging`

`kubectl apply -f elasticsearch_service.yaml`

`kubectl apply -f elasticsearch_statefulset.yaml`

`kubectl rollout status sts/es-cluster`

The last step will take a while. That's normal. You can kill it with "Ctrl/Command + C" and check status of pods via `get pods`. It's async job anyway. In average takes 3-5min to run all cluster pods.

`kubectl apply -f kibana-all.yaml`

You can now access Kibana dashboard by seting port forwarding via `kubectl port-forward`

Final step to setup fluentd to collect the logs and ship to Elasticsearch

`kubectl appl -f fluentd-all.yaml`

It will create

1) service account
2) custom role
3) required role binding
4) daemonSet to deploy on all compute nodes

Now just configure index pattern in Kibana in form of `logstash-*`

Pls don't get confused with logstash in the index name. Just for simplifcation it was setup to use logstash index name pattern. For simplicitty.

Sorry but Prometheus was de-scoped for now due to time constraint.






