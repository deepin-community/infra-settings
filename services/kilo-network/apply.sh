#!/bin/bash

kubectl apply -f crds.yaml
kubectl apply -f kilo-k3s.yaml
#web service
kubectl apply -f kilo-wg-gen-web.yaml
