FROM golang:alpine

ADD tools/cppcheck-2.8.zip /go/cppcheck-2.8.zip
COPY tools/glibc-2.35-r0.apk /go/glibc-2.35-r0.apk
COPY tools/glibc-bin-2.35-r0.apk /go/glibc-bin-2.35-r0.apk
ADD postAction.py /go/postAction.py
ADD entrypoint.sh /entrypoint.sh


# alpine repository mirror settings
RUN cp /etc/apk/repositories /etc/apk/repositories.bak; \
  sed -i "s/dl-cdn.alpinelinux.org/mirrors.tuna.tsinghua.edu.cn/g" /etc/apk/repositories; \
  echo "https://mirrors.aliyun.com/alpine/latest-stable/community/" >> /etc/apk/repositories; \
  echo "https://mirror.tuna.tsinghua.edu.cn/alpine/edge/testing" >> /etc/apk/repositories; \
  apk update && apk upgrade

RUN apk --no-cache add py3-requests curl git jq build-base shellcheck s3cmd; \
    mkdir /lib64 && ln -s /lib/libc.musl-x86_64.so.1 /lib64/ld-linux-x86-64.so.2; \
    unzip /go/cppcheck-2.8.zip && cd cppcheck-2.8 && \
    make install SRCDIR=build CFGDIR=/usr/bin/cfg FILESDIR=/usr/bin -j 16; cd -; \
    rm -rf cppcheck-2.8 /go/cppcheck-2.8.zip; \
    curl -o tscancode.tgz https://ci.uniontech.com/atreport/tools/tscancode.tgz && \
    tar -xzf tscancode.tgz && mv tscancode /usr/local/bin/ && rm -rf tscancode.tgz; \
    apk add --no-cache -U libstdc++; \
    apk add --allow-untrusted --force-overwrite /go/glibc-2.35-r0.apk && rm -rf /go/glibc-2.35-r0.apk; \
    apk add --allow-untrusted --force-overwrite /go/glibc-bin-2.35-r0.apk && rm -rf /go/glibc-bin-2.35-r0.apk; \
    curl --create-dirs -fsSLo /usr/local/bin/gosec https://ci.uniontech.com/atreport/tools/go_tools/gosec && \
    chmod 755 /usr/local/bin/gosec; \
    curl --create-dirs -fsSLo /usr/local/bin/golangci-lint https://ci.uniontech.com/atreport/tools/go_tools/golangci-lint && \
    chmod 755 /usr/local/bin/golangci-lint;

    
RUN chmod 0755 /entrypoint.sh


