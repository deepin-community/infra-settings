# 使用debian:latest作为基础镜像
FROM hub.cicd.getdeepin.org/library/debian:stable-slim

ENV container k3s

# 设置维护者信息
LABEL maintainer="hudeng@deepin.org"

# 更换清华源
RUN sed -i 's/deb.debian.org/mirrors.tuna.tsinghua.edu.cn/g' /etc/apt/sources.list.d/debian.sources \
    && sed -i 's/security.debian.org/mirrors.tuna.tsinghua.edu.cn\/debian-security/g' /etc/apt/sources.list.d/debian.sources

# 更新源并安装pkg-haskell-tools
RUN apt update && apt install -y curl pkg-haskell-tools jq osc && apt clean
RUN mkdir -p /work/ghc

# 配置工作目录
WORKDIR /work/ghc


ADD entrypoint.sh /entrypoint.sh

RUN chmod 0755 /entrypoint.sh
