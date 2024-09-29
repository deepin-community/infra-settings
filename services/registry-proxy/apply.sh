#!/bin/bash
kubectl create namespace registry-proxy
kubectl apply -f registry-proxy-config.yaml
kubectl apply -f manifests.yaml
