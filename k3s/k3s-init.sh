#!/bin/sh

# 本地（deepin操作系统)工具安装
sudo pip3 install ansible
#export PATH="$HOME/.local/bin:$PATH"
curl -sLS https://get.k3sup.dev | sh
sudo install -m 755 k3sup /usr/local/bin/
rm -r k3sup
go install github.com/squat/kilo/cmd/kgctl@latest

# ansible工具进行统一的服务器环境准备
cd ansible/
# 服务器免密登录配置（可选）
ansible-playbook ssh-settings.yml
# 服务器环境配置（必须）
ansible-playbook server-prepare.yml
# 服务器etcdctl工具配置（可选）
ansible-playbook etcdctl.yml
# 通过k3sup工具配置k3s服务
ansible-playbook k3sup.yml
cd ..
