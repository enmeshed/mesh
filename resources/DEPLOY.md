# Deployment from scratch

## 0. Environments

`default`, `development`, `production`

## 1. Operators

### Kafka

- Install Kafka operator: https://strimzi.io/

`helm repo add strimzi https://strimzi.io/charts/`
`helm install strimzi strimzi/strimzi-kafka-operator --namespace kafka --set watchAnyNamespace=true`

### Elasticsearch

- Install Elasticsearch operator: https://operatorhub.io/operator/elastic-cloud-eck

`kubectl apply -f https://download.elastic.co/downloads/eck/1.1.1/all-in-one.yaml`

### KubeDB

- Install KubeDB operator: https://kubedb.com/

```
$ helm repo add appscode https://charts.appscode.com/stable/
$ helm repo update
$ helm search repo appscode/kubedb
$ helm install kubedb-operator appscode/kubedb --version 0.12.0 \
  --namespace kube-system
$ helm install kubedb-catalog appscode/kubedb-catalog --version 0.12.0 --namespace kube-system
```

### Jaeger

- Install Jaeger operator: https://github.com/jaegertracing/jaeger-operator

```
kubectl create -f https://raw.githubusercontent.com/jaegertracing/jaeger-operator/master/deploy/crds/jaegertracing.io_jaegers_crd.yaml
kubectl create -f https://raw.githubusercontent.com/jaegertracing/jaeger-operator/master/deploy/service_account.yaml
kubectl create -f https://raw.githubusercontent.com/jaegertracing/jaeger-operator/master/deploy/role.yaml
kubectl create -f https://raw.githubusercontent.com/jaegertracing/jaeger-operator/master/deploy/role_binding.yaml
kubectl create -f https://raw.githubusercontent.com/jaegertracing/jaeger-operator/master/deploy/operator.yaml
```

## 2. Dev Environment

- `kubectl apply -f` for all resources under `/resources/dev`
- Helm charts:
-- `helm install goodbye resources/charts/clusterapp -f resources/dev/helm/goodbye.yaml --namespace development`

## 3. Runtime

- Mount gitops: `minikube mount /path/to/local/gitops:/gitops`
- Enable tunneling: `minikube tunnel` (see https://minikube.sigs.k8s.io/docs/handbook/accessing/)
