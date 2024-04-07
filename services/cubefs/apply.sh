#!/bin/bash
mkdir -p /tmp && tar xf cubefs-helm.tar.gz -C /tmp
helm upgrade --install cubefs /tmp/cubefs-helm -f ./cubefs-helm.yaml -n cubefs --create-namespace
rm -rf /tmp/cubefs-helm
