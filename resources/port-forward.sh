#!/bin/bash
while true
do
  kubectl port-forward svc/envoy-load-balancer 3000:80
done
