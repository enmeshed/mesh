# Deployment from scratch

## Infrastructure

If deploying in development, a working `minikube` is needed. On Windows:

- Install WSL: https://docs.microsoft.com/en-us/windows/wsl/install-win10
- Install Ubuntu 18 in WSL
- Install Node NVM inside Ubuntu: https://github.com/nvm-sh/nvm
- Install Node: `nvm install vX.X.X`
- Install Yarn: https://classic.yarnpkg.com/en/docs/install/#debian-stable
- Install Docker inside Ubuntu: https://docs.docker.com/engine/install/ubuntu/
- Install Helm: `https://helm.sh/docs/intro/install/`
- Start Docker (save this to a script, you will need to run it on restarts):
```
#!/bin/bash

sudo mkdir /sys/fs/cgroup/systemd
sudo mount -t cgroup -o none,name=systemd cgroup /sys/fs/cgroup/systemd
sudo service docker start
```
- Set up `miniube config`
  - Due to a `minikube` 1.11 bug, set `kubernetes-version` to 1.16
  - Set driver to `docker`
```
minikube config set driver docker
minikube config set kubernetes-version 1.16.0
```
- `minikube start`
- Configure addons:
```
minikube addons enable metrics-server
minikube addons enable dashboard
```
- Install NFS Provisioner (see below)


## K8s Namespaces

Create `default`, `development`, `production`, `kafka`

## Operators

### Kafka

- Install Kafka operator: https://strimzi.io/

`helm repo add strimzi https://strimzi.io/charts/`
`helm install strimzi strimzi/strimzi-kafka-operator --set watchAnyNamespace=true`

- Deploy Kafka resources

### Elasticsearch

- Install Elasticsearch operator: https://www.elastic.co/guide/en/cloud-on-k8s/current/index.html

`kubectl apply -f https://download.elastic.co/downloads/eck/1.1.1/all-in-one.yaml`

- Apply ES and Kibana resources
- Access Kibana and create Elasticsearch app user:
  - Get `elastic` root password from secret `es-primary-es-elastic-user`
  - `kubectl port-forward service/kibana-kb-http 5601`
  - Access `localhost:5601` and enter the credentials
  - Create `app` user under Settings; note password
  - Create `log` user under Settings for Jaeger/logging infrastructure; note password

### KubeDB

- Install KubeDB operator: https://kubedb.com/

```
helm repo add appscode https://charts.appscode.com/stable/
helm repo update
helm search repo appscode/kubedb
helm install kubedb-operator appscode/kubedb --version 0.12.0
helm install kubedb-catalog appscode/kubedb-catalog --version 0.12.0
```

- Apply MySQL and Redis resources
- Access MySQL and create MySQL app user

### Jaeger

- Install Jaeger operator: https://github.com/jaegertracing/jaeger-operator
```
helm repo add jaegertracing https://jaegertracing.github.io/helm-charts
helm install jaeger-operator jaegertracing/jaeger-operator -f resources/dev/helm/jaeger-operator.yaml
```
```
kubectl create -f https://raw.githubusercontent.com/jaegertracing/jaeger-operator/master/deploy/crds/jaegertracing.io_jaegers_crd.yaml
kubectl create -f https://raw.githubusercontent.com/jaegertracing/jaeger-operator/master/deploy/service_account.yaml
kubectl create -f https://raw.githubusercontent.com/jaegertracing/jaeger-operator/master/deploy/role.yaml
kubectl create -f https://raw.githubusercontent.com/jaegertracing/jaeger-operator/master/deploy/role_binding.yaml
kubectl create -f https://raw.githubusercontent.com/jaegertracing/jaeger-operator/master/deploy/operator.yaml
```
- Apply Jaeger resources

## 2. Dev Environment

- `kubectl apply -f` for all resources under `/resources/dev`
- Helm charts:
-- `helm install goodbye resources/charts/clusterapp -f resources/dev/helm/goodbye.yaml --namespace development`

## 3. Runtime

- Mount gitops: `minikube mount /path/to/local/gitops:/gitops`
- Enable tunneling: `minikube tunnel` (see https://minikube.sigs.k8s.io/docs/handbook/accessing/)
- Connect via proxy: `kubectl proxy --accept-hosts='.*'`

## 4. NFS Provisioner

While PVCs are broken in Minikube, we need to use the NFS Provisioner to provide working PVCs:

Install NFS in Minikube:
```
minikube ssh
sudo apt update && sudo apt install -y nfs-common
```

Disable broken provisioner:
```
minikube addons disable default-storageclass
minikube addons disable storage-provisioner
```

Apply provisioner resources:
```
kubectl apply -f resources/dev/nfs-provisioner.yaml
```

Make it the default:
https://kubernetes.io/docs/tasks/administer-cluster/change-default-storage-class/

Add `storageclass.kubernetes.io/is-default-class: "true"` to annotations
