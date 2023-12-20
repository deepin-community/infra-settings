# https://github.com/openSUSE/docker-containers/blob/master/derived_images/systemd/Dockerfile
FROM opensuse/leap:15.4

ENV container docker

#ENV https_proxy http://10.20.8.114:10809
#ENV http_proxy http://10.20.8.114:10809

# opensuse repository mirror settings
RUN zypper mr -da; zypper ar -cfg 'https://mirrors.tuna.tsinghua.edu.cn/opensuse/distribution/leap/$releasever/repo/oss/' mirror-oss; \
  zypper ar -cfg 'https://mirrors.tuna.tsinghua.edu.cn/opensuse/distribution/leap/$releasever/repo/non-oss/' mirror-non-oss; \
  zypper ar -cfg 'https://mirrors.tuna.tsinghua.edu.cn/opensuse/update/leap/$releasever/oss/' mirror-update; \
  zypper ar -cfg 'https://mirrors.tuna.tsinghua.edu.cn/opensuse/update/leap/$releasever/non-oss/' mirror-update-non-oss;

RUN https_proxy=http://10.20.52.80:7890 zypper ar -f -G https://download.opensuse.org/repositories/OBS:/Server:/Unstable/15.4/OBS:Server:Unstable.repo; \
  https_proxy=http://10.20.52.80:7890 zypper -n install -t pattern OBS_Server;zypper -n install gzip wireguard-tools iproute2 dpkg iputils vim;zypper clean;

# setup obs-backend and obs-sched configuration
RUN mkdir -p /srv/backup/; \
  mv /usr/lib/obs/server/BSConfig.pm /srv/backup/BSConfig.pm.bak; \
  mv /etc/sysconfig/obs-server /srv/backup/obs-server.bak; \
  #mv /srv/obs/configuration.xml /srv/backup/configuration.xml.bak; \
  mkdir -p /srv/obs/repos /run/passenger;

ADD config/BSConfig.pm /usr/lib/obs/server/BSConfig.pm
ADD config/obs-server /etc/sysconfig/obs-server
ADD config/configuration.xml /srv/obs/configuration.xml
COPY backend/patches /patches

# apply some patches
RUN patch -p1 -d /usr/lib/obs/server/build/ < /patches/0001-feat-add-deepin-auto-build-version-fromat.patch
RUN patch -p1 -d /usr/lib/obs/server/build/ < /patches/0002-dsc-Keep-everything.patch
RUN patch -p1 -d /usr/lib/obs/server/build/ < /patches/0003-feat-Add-linglong-build-support.patch
RUN patch -p1 -d /usr/lib/perl5/vendor_perl/5.26.1/Dpkg/ < /patches/0004-Add-sha512-support.patch
RUN patch -p1 -d /usr/lib/obs/server/ < /patches/0005-feat-Add-i386-build-support.patch
RUN patch -p1 -d /usr/lib/obs/server/ < /patches/0006-feat-Add-loong64-support.patch
RUN patch -p1 -d /usr/lib/obs/server/BSDispatcher/ < /patches/0007-obs-backend-service-dispatcher-add-muti-worker-hostlabel-support.patch
RUN patch -p1 -d /usr/lib/obs/server/build/ < /patches/0008-chore-obs-backend-build-dsc-script-add-eatmydata-support.patch

WORKDIR /srv/obs/

VOLUME [ "/srv/obs/" ]

ADD backend/entrypoint.sh /entrypoint.sh

CMD ["/bin/bash", "/entrypoint.sh"]
