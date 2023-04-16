#!/bin/bash

kubectl apply -f crds.yaml
kubectl apply -f kilo-k3s.yaml
#web service, support fo oauth2, will be used by deepinid
kubectl apply -f kilo-wg-gen-web-oidc-rbac.yaml

#kubectl -n default create secret generic kilo-wg-gen-web \
#    --from-literal=cookie-secret="" \
#    --from-literal=client-id="" \
#    --from-literal=client-secret=""
