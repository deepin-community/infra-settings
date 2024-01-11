#!/bin/bash
kubectl create namespace rsshub
helm repo add gabe565 https://charts.gabe565.com
helm repo update
helm -n rsshub install rsshub \
  --set env.TZ="Asia/Shanghai" \
    gabe565/rsshub -f deepin-values.yaml
