{{- define "envoyBootstrap"}}
#!/bin/sh

# make sure curl is installed
apk --no-cache add curl

# Download Envoy native Jaeger tracing
curl -Lo /scratch/libjaegertracing_plugin.so {{ .Values.envoy.tracing.pluginUrl }}

# Create sidecar envoy yaml
cat > /scratch/envoy.yaml <<HEREDOC
node:
  metadata:
    role: sidecar
    environment: "{{ .Values.environment }}"
    provider: "{{ .Values.provider }}"
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
        address: "{{ .Values.controlPlaneAddress }}"
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
        service_name: "proxy:{{ .Values.environment }}_{{ .Values.provider }}"
        sampler:
          type: {{ .Values.envoy.tracing.sampler.type }}
          param: {{ .Values.envoy.tracing.sampler.param }}
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

# Punt to envoy
envoy -c /scratch/envoy.yaml --service-node ${K_POD_NAMESPACE}_${K_POD_NAME} --service-cluster {{ .Values.envoy.serviceCluster }}
{{- end }}
