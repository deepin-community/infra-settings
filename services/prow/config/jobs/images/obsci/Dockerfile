FROM debian:latest

ENV container docker

# debian repository mirror settings
RUN cp /etc/apt/sources.list.d/debian.sources /etc/apt/sources.list.d/debian.sources.bak; \
  sed -i "s/deb.debian.org/mirrors.tuna.tsinghua.edu.cn/g" /etc/apt/sources.list.d/debian.sources; \
  apt update

RUN apt install -y yq curl; \
  ln -s /usr/bin/xq-python /usr/bin/xq;
  #sudo pip3 install -i https://pypi.tuna.tsinghua.edu.cn/simple xmltodict; \
  #sudo pip3 install -i https://pypi.tuna.tsinghua.edu.cn/simple yq;


ADD entrypoint.sh /entrypoint.sh

RUN chmod 0755 /entrypoint.sh;

#CMD ["/bin/bash", "/entrypoint.sh"]
