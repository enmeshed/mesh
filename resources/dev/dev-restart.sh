#! /usr/bin/env bash

kubectl --namespace=development rollout restart deployment/worker-io
kubectl --namespace=development rollout restart deployment/api
