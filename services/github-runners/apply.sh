#!/bin/sh
kubectl create secret generic controller-manager \
    -n actions-runner-system \
    --from-literal=github_token=$GITHUB_TOKEN

kubectl apply -f actions-runner-controller.yaml --server-side

# kubectl apply -f runnerdeployment.yml
