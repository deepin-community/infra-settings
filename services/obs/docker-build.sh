#!/bin/bash

sudo -E docker build -t hub.deepin.com/k3s/obs/api -f api/Dockerfile .
sudo -E docker build -t hub.deepin.com/k3s/obs/src -f src/Dockerfile .
sudo -E docker build -t hub.deepin.com/k3s/obs/backend -f backend/Dockerfile .
sudo -E docker build -t hub.deepin.com/k3s/obs/scheduler -f scheduler/Dockerfile .
sudo -E docker build -t hub.deepin.com/k3s/obs/worker -f worker/Dockerfile .
sudo -E docker push hub.deepin.com/k3s/obs/api
sudo -E docker push hub.deepin.com/k3s/obs/src
sudo -E docker push hub.deepin.com/k3s/obs/backend
sudo -E docker push hub.deepin.com/k3s/obs/scheduler
sudo -E docker push hub.deepin.com/k3s/obs/worker
