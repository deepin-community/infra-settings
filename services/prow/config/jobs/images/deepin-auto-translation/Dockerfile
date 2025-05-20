FROM alpine:latest

# 配置清华 alpine 源
RUN cp /etc/apk/repositories /etc/apk/repositories.bak && \
    sed -i 's|dl-cdn.alpinelinux.org|mirrors.tuna.tsinghua.edu.cn|g' /etc/apk/repositories && \
    apk update

# 安装必要的工具和依赖
RUN apk add --no-cache \
    bash \
    libstdc++ \
    curl \
    git && \
    # 清理缓存
    rm -rf /var/cache/apk/*


# 复制翻译脚本到镜像中
ADD deepin-auto-translation /app/deepin-auto-translation

# 安装bun
# 这里使用 curl 下载并执行安装脚本
RUN curl -fsSL https://bun.sh/install | bash
ENV BUN_INSTALL="~/.bun" \
    PATH="$BUN_INSTALL/bin:$PATH"

# 安装transifex
# 这里使用 curl 下载并执行安装脚本
RUN curl -o- https://raw.githubusercontent.com/transifex/cli/master/install.sh | bash && mv /tx /usr/local/bin/tx

# 安装脚本运行依赖
RUN cd /app/deepin-auto-translation && BUN_INSTALL="~/.bun" ~/.bun/bin/bun install

# 复制入口点脚本到镜像中
COPY entrypoint /app/entrypoint

RUN chmod +x /app/entrypoint

# 设置入口点
#ENTRYPOINT ["bash", "/app/entrypoint"]
