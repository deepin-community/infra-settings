# https://github.com/openSUSE/docker-containers/blob/master/derived_images/systemd/Dockerfile
FROM opensuse/leap:15.5

ENV container docker

# opensuse repository mirror settings
RUN zypper mr -da; zypper ar -cfg 'https://mirrors.tuna.tsinghua.edu.cn/opensuse/distribution/leap/$releasever/repo/oss/' mirror-oss; \
  zypper ar -cfg 'https://mirrors.tuna.tsinghua.edu.cn/opensuse/distribution/leap/$releasever/repo/non-oss/' mirror-non-oss; \
  zypper ar -cfg 'https://mirrors.tuna.tsinghua.edu.cn/opensuse/update/leap/$releasever/oss/' mirror-update; \
  zypper ar -cfg 'https://mirrors.tuna.tsinghua.edu.cn/opensuse/update/leap/$releasever/non-oss/' mirror-update-non-oss;

RUN zypper ar -f -G https://download.opensuse.org/repositories/OBS:/Server:/Unstable/15.5/OBS:Server:Unstable.repo; \
  zypper ar -f -G https://download.opensuse.org/repositories/openSUSE:/Tools/15.5/openSUSE:Tools.repo; \
  zypper -n install git-buildpackage patch fakeroot obs-service-gbp obs-service-set_version obs-server vim xz \
  obs-service-cargo_vendor cargo sudo go1.18 python3-libarchive-c gzip bzip2; zypper clean;

# setup obs-src configuration
RUN mkdir -p /srv/backup/; \
  mv /usr/lib/obs/server/BSConfig.pm /srv/backup/BSConfig.pm.bak; \
  mv /etc/sysconfig/obs-server /srv/backup/obs-server.bak; \
  #mv /srv/obs/configuration.xml /srv/backup/configuration.xml.bak; \
  mkdir -p /srv/obs/repos /run/passenger /patches /usr/lib/obs/service;

ADD config/BSConfig.pm /usr/lib/obs/server/BSConfig.pm
ADD config/obs-server /etc/sysconfig/obs-server
ADD config/configuration.xml /srv/obs/configuration.xml
COPY src/patches /patches
COPY src/service /usr/lib/obs/service
COPY src/server /

# apply some patches
RUN patch -p2 -d /usr/lib/obs/service/TarSCM/ < /patches/0001-obs-tar-scm.patch
RUN patch -p2 -d /usr/lib/obs/service/TarSCM/ < /patches/0003-chore-remove-dpkg-parsechangelog-warning.patch
RUN patch -p2 -d /usr/lib/obs/service/TarSCM/scm < /patches/0005-fix-cache-dir-lock-file-improper-cleanin.patch
RUN patch -p2 -d /usr/lib/obs/service/TarSCM/ < /patches/0006-feat-commit-version-update-timestamp.patch
# RUN patch -p3 -d /usr/lib/obs/server < /patches/0002-feat-Add-linglong-build-support.patch
RUN tar xf /obs-server.tar -C /usr/lib/obs/; rm /obs-server.tar
RUN patch -p1 -d /usr/lib/obs/server/build/ < /patches/0004-fix-debian-i386-arch-incorrect-excluded-when-build.patch

WORKDIR /srv/obs/

VOLUME [ "/srv/obs/" ]

ADD src/entrypoint.sh /entrypoint.sh

CMD ["/bin/bash", "/entrypoint.sh"]
