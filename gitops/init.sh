#!/bin/bash

# Download Envoy native Jaeger tracing
JAEGER_VERSION=v0.4.2
curl -Lo /scratch/libjaegertracing_plugin.so https://github.com/jaegertracing/jaeger-client-cpp/releases/download/$JAEGER_VERSION/libjaegertracing_plugin.linux_amd64.so


# Create sidecar envoy yaml
cat > /scratch/envoy-sidecar.yaml <<HEREDOC
node:
  metadata:
    role: sidecar
    environment: "${MESH_ENVIRONMENT}"
    provider: "${MESH_PROVIDER}"
dynamic_resources:
  cds_config: {ads: {}}
  lds_config: {ads: {}}
  ads_config:
    api_type: GRPC
    grpc_services:
      envoy_grpc:
        cluster_name: ads_cluster
static_resources:
  clusters:
  - name: ads_cluster
    connect_timeout: { seconds: 5 }
    type: STRICT_DNS
    hosts:
    - socket_address:
        address: "${MESH_CONTROL_PLANE_ADDRESS}"
        port_value: 12000
    lb_policy: ROUND_ROBIN
    http2_protocol_options: {}
    upstream_connection_options:
      # configure a TCP keep-alive to detect and reconnect to the admin
      # server in the event of a TCP socket disconnection
      tcp_keepalive: {}
tracing:
  http:
    name: envoy.dynamic.ot
    config:
      library: /scratch/libjaegertracing_plugin.so
      config:
        service_name: "${MESH_ENVIRONMENT}_${MESH_PROVIDER}"
        sampler:
          type: const
          param: 1
        reporter:
          localAgentHostPort: localhost:6831
        headers:
          jaegerDebugHeader: jaeger-debug-id
          jaegerBaggageHeader: jaeger-baggage
          traceBaggageHeaderPrefix: uberctx-
        baggage_restrictions:
          denyBaggageOnInitializationFailure: false
          hostPort: ""
admin:
  access_log_path: "/dev/stdout"
  address:
    socket_address:
      address: 0.0.0.0
      port_value: 9000
HEREDOC

# Root app init
# cd /app
# npm install
