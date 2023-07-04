# https://github.com/openSUSE/docker-containers/blob/master/derived_images/systemd/Dockerfile
FROM opensuse/leap:15.4

ENV container docker

# opensuse repository mirror settings
RUN zypper mr -da; zypper ar -cfg 'https://mirrors.tuna.tsinghua.edu.cn/opensuse/distribution/leap/$releasever/repo/oss/' mirror-oss; \
  zypper ar -cfg 'https://mirrors.tuna.tsinghua.edu.cn/opensuse/distribution/leap/$releasever/repo/non-oss/' mirror-non-oss; \
  zypper ar -cfg 'https://mirrors.tuna.tsinghua.edu.cn/opensuse/update/leap/$releasever/oss/' mirror-update; \
  zypper ar -cfg 'https://mirrors.tuna.tsinghua.edu.cn/opensuse/update/leap/$releasever/non-oss/' mirror-update-non-oss;

RUN zypper ar -f -G https://download.opensuse.org/repositories/OBS:/Server:/Unstable/15.4/OBS:Server:Unstable.repo; \
  zypper -n install -t pattern OBS_Server; zypper -n install gzip;zypper clean;

# setup obs-backend and obs-sched configuration
RUN mkdir -p /srv/backup/; \
  mv /usr/lib/obs/server/BSConfig.pm /srv/backup/BSConfig.pm.bak; \
  mv /etc/sysconfig/obs-server /srv/backup/obs-server.bak; \
  #mv /srv/obs/configuration.xml /srv/backup/configuration.xml.bak; \
  mkdir -p /srv/obs/repos /run/passenger;

ADD config/BSConfig.pm /usr/lib/obs/server/BSConfig.pm
ADD config/obs-server /etc/sysconfig/obs-server
ADD config/configuration.xml /srv/obs/configuration.xml

WORKDIR /srv/obs/

VOLUME [ "/srv/obs/" ]

ADD backend/entrypoint.sh /entrypoint.sh

CMD ["/bin/bash", "/entrypoint.sh"]
