FROM alpine:latest

# 配置清华 alpine 源
RUN cp /etc/apk/repositories /etc/apk/repositories.bak && \
    sed -i 's|dl-cdn.alpinelinux.org|mirrors.tuna.tsinghua.edu.cn|g' /etc/apk/repositories && \
    apk update

# 安装必要的工具和依赖
RUN apk add --no-cache \
    git \
    perl \
    perl-xml-libxml \
    perl-config-tiny \
    py3-requests && \
    # 添加 GitHub CLI (gh)
    # https_proxy=http://10.20.6.92:1080 curl -Lo gh.tar.gz https://github.com/cli/cli/releases/download/v2.70.0/gh_2.70.0_linux_amd64.tar.gz && \
    # tar -xzf gh.tar.gz && \
    # mv gh_2.70.0_linux_amd64/bin/gh /usr/bin/gh && \
    # rm -rf gh.tar.gz gh_2.70.0_linux_amd64 && \
    # 清理缓存
    rm -rf /var/cache/apk/*

# 复制deepin-desktop-ts-convert脚本
COPY desktop_ts_convert.pl /usr/bin/deepin-desktop-ts-convert
RUN chmod +x /usr/bin/deepin-desktop-ts-convert

# 复制入口点脚本到镜像中
COPY entrypoint.py /app/entrypoint.py

RUN chmod +x /app/entrypoint.py

# 设置入口点
#ENTRYPOINT ["python3", "/app/entrypoint.py"]
