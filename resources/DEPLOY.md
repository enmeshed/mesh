# Deployment from scratch

## Baseline Infrastructure

If deploying in development, a working `minikube` is needed. On Windows:

- Install WSL: https://docs.microsoft.com/en-us/windows/wsl/install-win10
- Install Ubuntu 20 in WSL
- Set Git globals:
```
git config --global user.email "you@example.com"
git config --global user.name "Your Name"
git config --global credential.helper store
```
- Install Golang: https://golang.org/doc/install
- Install Node NVM inside Ubuntu: https://github.com/nvm-sh/nvm
- Install Node: `nvm install vX.X.X`
- Install Yarn: https://classic.yarnpkg.com/en/docs/install/#debian-stable
- Install Docker Desktop for Windows
- Integrate Docker Desktop with Ubuntu WSL installation in Docker Desktop settings
- Install Helm: `https://helm.sh/docs/intro/install/`
- Install Minikube: https://minikube.sigs.k8s.io/docs/start/
- Install Kubectl: https://kubernetes.io/docs/tasks/tools/install-kubectl/

## Kubernetes

- Set up Minikube
```
minikube config set driver docker
minikube config set cpus 4
minikube config set memory 16384
minikube start --mount --mount-string="/home/wcj/dev/mesh/gitops:/gitops"
```
- Configure addons:
```
minikube addons enable metrics-server
minikube addons enable dashboard
```
- Fix persistent storage bug (should only be needed until minikube 1.13)
```
minikube addons disable storage-provisioner
```
```
minikube ssh

sudo mkdir /persistent_volumes
sudo chmod 777 /persistent_volumes
exit
```
```
kubectl apply -f resources/dev/minikube-fixes/storage-provisioner.yaml
```

## Ops Infrastructure

- Install Kafka operator: https://strimzi.io/
```
helm repo add strimzi https://strimzi.io/charts/
helm install strimzi strimzi/strimzi-kafka-operator --set watchAnyNamespace=true
```
- Install Elasticsearch operator: https://www.elastic.co/guide/en/cloud-on-k8s/current/index.html
```
kubectl apply -f https://download.elastic.co/downloads/eck/1.2.0/all-in-one.yaml
```
- Install KubeDB operator: https://kubedb.com/
```
helm repo add appscode https://charts.appscode.com/stable/
helm repo update
helm search repo appscode/kubedb
helm install kubedb-operator appscode/kubedb --version 0.12.0
helm install kubedb-catalog appscode/kubedb-catalog --version 0.12.0
```
- Install Jaeger operator: https://github.com/jaegertracing/jaeger-operator
```
helm repo add jaegertracing https://jaegertracing.github.io/helm-charts
helm install jaeger-operator jaegertracing/jaeger-operator -f resources/dev/helm/jaeger-operator.yaml
```

## Databases

- Create the development namespace
- Deploy Kafka cluster
- Deploy Elasticsearch cluster
- Deploy Redis
- Deploy MySQL
```
kubectl create namespace development
kubectl apply -f resources/dev/kafka.yaml
kubectl apply -f resources/dev/elasticsearch.yaml
kubectl apply -f resources/dev/redis.yaml
kubectl apply -f resources/dev/mysql.yaml
```

## MySQL Users and Access

- Deploy phpMyAdmin:
```
helm repo add bitnami https://charts.bitnami.com/bitnami
helm install phpmyadmin bitnami/phpmyadmin -f resources/dev/helm/phpmyadmin.yaml
```
- Access phpMyAdmin: (use secret default/mysql-auth)
```
kubectl port-forward --namespace default svc/phpmyadmin 8080:80
```
- Create mysql user `app`
```
CREATE USER 'app'@'%' IDENTIFIED WITH mysql_native_password AS 'App123$';GRANT SELECT, INSERT, UPDATE, DELETE, CREATE, DROP, FILE, INDEX, ALTER, SHOW DATABASES, CREATE TEMPORARY TABLES, LOCK TABLES, REPLICATION CLIENT, CREATE VIEW, EVENT, TRIGGER, SHOW VIEW, CREATE ROUTINE, ALTER ROUTINE, EXECUTE ON *.* TO 'app'@'%' REQUIRE NONE WITH MAX_QUERIES_PER_HOUR 0 MAX_CONNECTIONS_PER_HOUR 0 MAX_UPDATES_PER_HOUR 0 MAX_USER_CONNECTIONS 0;
```
- Create mysql databases `app` and `app_development`

## Elasticsearch Users and Access

- Deploy temporary Kibana instance for cluster admin tasks
```
kubectl apply -f resources/dev/kibana-internal.yaml
```
- Access temporary Kibana instance at https://localhost:5601 (use secret default/es-primary-es-elastic-user)
```
kubectl port-forward svc/kibana-internal-kb-http 5601:5601
```
- Create ES users `app` (`App123$`) and `logging` (`Log123$`) with corresponding roles
- Remove temporary kibana instance
```
kubectl delete -f resources/dev/kibana-internal.yaml
```

## Initial Build
- Create initial full build, which will be deployed when containers are created:
```
yarn install
cd gitops
npm install
cd ..
yarn run build
```

## Core internal services
- Create secrets for core services
  - `development/injected-secrets` must contain:
    - `MYSQL_PASSWORD`: password for the `app` user created above
    - `ELASTICSEARCH_PASSWORD`: password for the `app` user created above
    - `JWT_SIGNING_SECRET`: HS256 key for signing tokens

```
apiVersion: v1
kind: Secret
metadata:
  name: injected-secrets
  namespace: development
type: Opaque
stringData:
  MYSQL_PASSWORD: App123$
  ELASTICSEARCH_PASSWORD: App123$
  JWT_SIGNING_SECRET: 6351665468576D5A
```

- Deploy IO worker
```
helm install worker-io resources/charts/clusterapp -f resources/dev/helm/worker-io.yaml --namespace development
```

## Ingress
- Deploy Bowser, Envoy, and Envoy LB
```
kubectl apply -f resources/dev/bowser.yaml
kubectl apply -f resources/dev/envoy-ingress.yaml
kubectl apply -f resources/dev/envoy-local-loadbalancer.yaml
```

- Open channel into cluster (localhost:3000)
```
resources/port-forward.sh
```

## Logging
- Create secrets for Jaeger
  - `default/jaeger-elasticsearch-secret` must contain:
    - `ES_USERNAME`: `logging`
    - `ES_PASSWORD`: the password you created above
```
apiVersion: v1
kind: Secret
metadata:
  name: jaeger-elasticsearch-secret
  namespace: default
type: Opaque
stringData:
  ES_USERNAME: logging
  ES_PASSWORD: xxx
```

- Deploy Jaeger
```
kubectl apply -f resources/dev/jaeger.yaml
```

- Deploy prod kibana
```
kubectl apply -f resources/dev/kibana.yaml
```

- Jaeger is now accessible at http://localhost:3000/jaeger

## HTTP API
- Deploy API worker
```
helm install api resources/charts/clusterapp -f resources/dev/helm/api.yaml --namespace development
```

## Runtime

- Connect via proxy: `kubectl proxy --accept-hosts='.*'`
- Connect via ingress: `resources/port-forward.sh`
