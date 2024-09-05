FROM debian:testing

# RUN sed -i -e 's/deb.debian.org/mirrors.cernet.edu.cn/g' /etc/apt/sources.list.d/debian.sources
RUN apt-get update && apt-get -y install ben wget
WORKDIR /ben/
COPY config /ben/config
COPY ben.sh /usr/local/bin/
# /ben/html
RUN mkdir -p html
# RUN echo "nameserver 10.20.0.10" > /etc/resolv.conf
CMD [ "ben.sh" ]

