#!/bin/bash

#generate server key files 
openssl genrsa -out config/certs/server.key 1024
openssl req -new -key config/certs/server.key \
        -out config/certs/server.csr
openssl x509 -req -days 365 -in config/certs/server.csr \
        -signkey config/certs/server.key -out config/certs/server.crt

sudo docker build -t hub.deepin.com/k3s/obs/apiv2
