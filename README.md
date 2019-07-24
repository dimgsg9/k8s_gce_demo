# Draft notes

## Approach

1. Ansible (seems like i will deprecate it, bash does the job so far)
1. `gcloud` CLI.
1. Ansible calling `gcloud` CLI via shell module.
1. Ensure `cfssl` is installed. And most recent version of `openssl` is installed too. Ensure bash v > 4.x. For OSX install openssl with brew and make sure to export PATH.

On Mac (OSX) even if openssl is installed (with `brew`) it doesn't link the binaries nor it adds PATH, might be workarounded like so:
`export PATH=/usr/local/opt/openssl/bin:$PATH`

`openssl version -a | head -n 1 | awk '{print $1}'` may return LibreSSL

Useful article regarding OpenSSL vs LibreSSL challenge in OSX:
https://medium.com/@timmykko/using-openssl-library-with-macos-sierra-7807cfd47892

Important: md5sum is not available in OSX by default.

`brew install md5sha1sum`

When deploying the cluster it will ask you for your SSH key passphrase many many time (a little annoying), so if has been set you will need to key in passphrase a number of times. Take it easy huh :)

Authentication to GCP API via service account - not in scope but can be done.

Don't forget to get your kubectl binaries to your PATH:

Example:
`export PATH=/Users/dmitry/Code/k8s_gce_demo/kubernetes/client/bin:$PATH`


To do: `ENABLE_PROMETHEUS_MONITORING="${KUBE_ENABLE_PROMETHEUS_MONITORING:-false}"`

### Deploy Web UI (optinal)
`kubectl apply -f https://raw.githubusercontent.com/kubernetes/dashboard/v2.0.0-beta1/aio/deploy/recommended.yaml`

Got it working with Ingress via GCP LB controller :)

### Create development namespace
`kubectl create -f example_guestbook/dev_namespace.yaml`

`kubectl apply -f example_guestbook/redis-master-deployment.yaml --namespace=development`

`kubectl apply -f example_guestbook/redis-master-service.yaml --namespace=development`

`kubectl apply -f example_guestbook/redis-slave-deployment.yaml --namespace=development`

`kubectl apply -f example_guestbook/redis-slave-service.yaml --namespace=development`

`kubectl apply -f example_guestbook/frontend-deployment.yaml --namespace=development`

`kubectl apply -f example_guestbook/frontend-service.yaml --namespace=development`

It may take some time for load balancer created by ingress controller to start sending traffic as it's a little slow to mark backend destination (service) as healthy.

## Installing helm via autoinstaller (given I don't know what OS you're using)
`curl -L https://git.io/get_helm.sh | bash`

`kubectl apply -f helm_setup/rbac_setup.yaml`

`helm init --service-account tiller --tiller-namespace development --history-max 200`

## Integrating GitLab CI
`kubectl apply -f gitlab_setup/gitlab_admin_sa.yaml`

`
