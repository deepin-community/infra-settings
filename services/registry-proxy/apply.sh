#!/bin/bash
kubectl create namespace registry-proxy
kubectl apply -f manifests.yaml
kubectl apply -f registry-proxy-config.yaml
