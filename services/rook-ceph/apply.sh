#!/bin/bash
helm repo add rook-release https://charts.rook.io/release
# install rook operator
helm upgrade --install rook-ceph-operator rook-release/rook-ceph -f operator-values.yaml -n rook-ceph --create-namespace
# install ceph cluster （高危操作，会格式化掉集群中磁盘，因此在混或集群中需要小心配置）
helm upgrade --install rook-ceph-cluster rook-release/rook-ceph-cluster -f cluster-values.yaml -n rook-ceph --create-namespace
