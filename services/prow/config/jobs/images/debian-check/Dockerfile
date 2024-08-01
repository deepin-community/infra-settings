FROM alpine:latest

# alpine repository mirror settings
RUN cp /etc/apk/repositories /etc/apk/repositories.bak; \
  sed -i "s/dl-cdn.alpinelinux.org/mirrors.tuna.tsinghua.edu.cn/g" /etc/apk/repositories; \
  apk update

RUN apk --no-cache add py3-requests;apk --no-cache add dpkg

ADD entrypoint /entrypoint

RUN chmod 0755 /entrypoint;