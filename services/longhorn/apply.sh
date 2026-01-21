#!/bin/bash

helm repo add longhorn https://charts.longhorn.io
helm repo update

helm upgrade --install longhorn longhorn/longhorn --namespace longhorn-system -f deepin-values.yaml --create-namespace --version 1.8.1
