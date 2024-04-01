#!/bin/bash
helm repo add gitea-charts https://dl.gitea.com/charts/
helm install gitea gitea-charts/gitea -n gitea

#helm show values gitea-charts/gitea > deepin-values.yaml
#helm show readme gitea-charts/gitea > README.md
helm upgrade --install gitea -f deepin-values.yaml gitea-charts/gitea -n gitea --create-namespace
