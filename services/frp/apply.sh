#!/bin/bash
kubectl create namespace frp
kubectl create secret generic frpc-config --from-file=./frpc/frpc.toml -n frp
kubectl apply -f frpc/deployment.yaml -n frp
