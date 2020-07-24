#! /usr/bin/env bash

kubectl --namespace=development rollout restart deployment/worker-io
kubectl --namespace=development rollout restart deployment/api

kubectl --namespace=development rollout status deployment/api
kubectl --namespace=development rollout status deployment/worker-io
