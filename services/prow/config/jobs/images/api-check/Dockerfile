FROM alpine:latest

ADD deepin-abigail /deepin-abigail
ADD fastFilesCompare.json /fastFilesCompare.json
ADD postAction.py /postAction.py
ADD entrypoint.sh /entrypoint.sh

# alpine repository mirror settings
RUN cp /etc/apk/repositories /etc/apk/repositories.bak; \
  sed -i "s/dl-cdn.alpinelinux.org/mirrors.tuna.tsinghua.edu.cn/g" /etc/apk/repositories; \
  sed -i "s/v3.15/v3.20/g" /etc/apk/repositories; \
  echo "https://mirrors.aliyun.com/alpine/latest-stable/community/" >> /etc/apk/repositories; \
  echo "https://mirror.tuna.tsinghua.edu.cn/alpine/edge/testing" >> /etc/apk/repositories; \
  apk update && apk upgrade

RUN apk --no-cache add py3-requests git quilt s3cmd; apk upgrade musl; \
    mkdir /lib64 && ln -s /lib/libc.musl-x86_64.so.1 /lib64/ld-linux-x86-64.so.2; \
    mv /deepin-abigail /usr/local/bin/deepin-abigail; \
    # 安装universal-ctags：add runtime dependencies
    apk --update --no-cache add jansson yaml libxml2 && \
    # add build dependencies
    apk --update --no-cache add --virtual build-deps autoconf make gcc automake musl-dev \
    jansson-dev yaml-dev libxml2-dev && \
    # build, install universal-ctags
    git clone http://github.com/universal-ctags/ctags.git ~/ctags && \
    cd ~/ctags && ./autogen.sh && \
    ./configure && make && make install && \
    ln -s /usr/local/bin/ctags /usr/bin/ctags-universal && \
     # cleanup
    cd ~ && rm -rf ctags && apk del build-deps

RUN chmod 0755 /entrypoint.sh