FROM alpine:latest

ENV container docker

# alpine repository mirror settings
RUN cp /etc/apk/repositories /etc/apk/repositories.bak; \
  sed -i "s/dl-cdn.alpinelinux.org/mirrors.tuna.tsinghua.edu.cn/g" /etc/apk/repositories; \
  apk update

RUN apk add py3-pip py3-requests; \
  pip3 install -i https://pypi.tuna.tsinghua.edu.cn/simple pika;


ADD githubreporter /githubreporter

RUN chmod +x /githubreporter
