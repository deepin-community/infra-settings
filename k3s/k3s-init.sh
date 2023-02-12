#!/bin/sh

# 本地（deepin操作系统)工具安装
sudo apt install ansible
curl -sLS https://get.k3sup.dev | sh
sudo install k3sup /usr/local/bin/


# ansible工具进行统一的服务器环境准备
cd ansible/
# 服务器免密登录配置（可选）
ansible-playbook ssh-settings.yml -i inventory/deepinci-cluster/hosts.ini
# 服务器环境配置（必须）
ansible-playbook server-prepare.yml -i inventory/deepinci-cluster/hosts.ini
# 服务器etcdctl工具配置（可选）
ansible-playbook etcdctl.yml -i inventory/deepinci-cluster/hosts.ini
# 通过k3sup工具配置k3s服务
ansible-playbook k3sup.yml -i inventory/deepinci-cluster/hosts.ini
cd ..