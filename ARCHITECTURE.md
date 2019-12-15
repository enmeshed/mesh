# Mesh

A launchpad for a microservices-oriented app platform.

## Core Techs

- Node 10
- Kubernetes
- Helm
- Helm Diff (https://github.com/databus23/helm-diff)
- Envoy
- Webpack (bundling microservices)
- Jaeger
- Prometheus
- OpenTracing
- Nginx (static content)

## Notes

- Cli to create new services
- Cli to import helm charts
- Node 10 required
- Envoy front proxy/load balancer: https://www.envoyproxy.io/learn/front-proxy
- Envoy service mesh: https://www.envoyproxy.io/learn/service-mesh
  - See here for how to load balance across grpc using envoy: https://github.com/GoogleCloudPlatform/grpc-gke-nlb-tutorial
- Make sure microservices forward Jaeger/other headers (e.g. headers beginning with x-platform-*) - see: https://github.com/yurishkuro/opentracing-tutorial/tree/master/nodejs/lesson03
- "Eject" individual configuration files for manual control
- Deploy built code to GitOps repo
- Install Jaeger Operator: https://github.com/jaegertracing/jaeger-operator#installing-the-operator
- gRPC services:
  - Use Contexty to collect and propagate context
  - Use https://github.com/bojand/grpc-caller
  - Use grpc-js: https://github.com/grpc/grpc-node/tree/master/packages/grpc-js/src
  - May be necessary to fork the Caller to work with the pure-js library
  - All proto files must be bundled into GitOps because they are needed by the live clients
  - Also consider protocol compiler, docs here: https://github.com/grpc/grpc-node/issues/931
  - proto-loader can't be used as an ES6 Module

## Environments

- A Deployment maps service names to Helm releases
- An environment maps strong service names to prefixed names
- Each Envoy sidecar knows what environment its' in and sends this to the Envoy control plane

## Yeoman

- Check out Envoy protocols for appropriate version into `protocols/`
