# https://github.com/openSUSE/docker-containers/blob/master/derived_images/systemd/Dockerfile
FROM opensuse/leap:15.4

ENV container docker

# opensuse repository mirror settings
RUN zypper mr -da; zypper ar -cfg 'https://mirrors.tuna.tsinghua.edu.cn/opensuse/distribution/leap/$releasever/repo/oss/' mirror-oss; \
  zypper ar -cfg 'https://mirrors.tuna.tsinghua.edu.cn/opensuse/distribution/leap/$releasever/repo/non-oss/' mirror-non-oss; \
  zypper ar -cfg 'https://mirrors.tuna.tsinghua.edu.cn/opensuse/update/leap/$releasever/oss/' mirror-update; \
  zypper ar -cfg 'https://mirrors.tuna.tsinghua.edu.cn/opensuse/update/leap/$releasever/non-oss/' mirror-update-non-oss;

RUN zypper ar -f -G https://download.opensuse.org/repositories/OBS:/Server:/Unstable/15.4/OBS:Server:Unstable.repo; \
  zypper -n install obs-worker; zypper clean;

# setup obs-backend configuration
RUN mkdir -p /srv/backup/; \
  mv /etc/sysconfig/obs-server /etc/sysconfig/obs-server.bak;

ADD config/obs-server /etc/sysconfig/obs-server
ADD worker/config/obs-worker /etc/sysconfig/obs-worker

WORKDIR /srv/obs/

VOLUME [ "/srv/obs/log/" ]

ADD worker/entrypoint.sh /entrypoint.sh

CMD ["/bin/bash", "/entrypoint.sh"]
