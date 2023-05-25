#!/bin/bash

mkdir -p .secret
openssl rand -hex 20 > .secret/secret
#kubectl create namespace prow
#kubectl create secret -n prow generic hmac-token --from-file=hmac=.secret/secret
#kubectl create secret -n prow generic github-token --from-file=cert=.secret/deepin-community-ci-bo.pem --from-literal=appid=229710
#kubectl apply -f starter-minio.yml
kubectl apply --server-side=true -f prowjob-crd/prowjob_customresourcedefinition.yaml
kubectl apply -f starter-minio.yml
