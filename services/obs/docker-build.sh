#!/bin/bash

sudo docker build -t hub.deepin.com/k3s/obs/api -f api/Dockerfile .
sudo docker build -t hub.deepin.com/k3s/obs/src -f src/Dockerfile .
sudo docker build -t hub.deepin.com/k3s/obs/backend -f backend/Dockerfile .
sudo docker build -t hub.deepin.com/k3s/obs/scheduler -f scheduler/Dockerfile .
sudo docker build -t hub.deepin.com/k3s/obs/worker -f worker/Dockerfile .
sudo docker push hub.deepin.com/k3s/obs/api
sudo docker push hub.deepin.com/k3s/obs/src
sudo docker push hub.deepin.com/k3s/obs/backend
sudo docker push hub.deepin.com/k3s/obs/scheduler
sudo docker push hub.deepin.com/k3s/obs/worker
