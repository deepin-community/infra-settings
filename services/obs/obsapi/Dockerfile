# https://github.com/openSUSE/docker-containers/blob/master/derived_images/systemd/Dockerfile
FROM opensuse/leap:15.4

ENV container docker

# opensuse repository mirror settings
RUN zypper mr -da; zypper ar -cfg 'https://mirrors.tuna.tsinghua.edu.cn/opensuse/distribution/leap/$releasever/repo/oss/' mirror-oss; \
  zypper ar -cfg 'https://mirrors.tuna.tsinghua.edu.cn/opensuse/distribution/leap/$releasever/repo/non-oss/' mirror-non-oss; \
  zypper ar -cfg 'https://mirrors.tuna.tsinghua.edu.cn/opensuse/update/leap/$releasever/oss/' mirror-update; \
  zypper ar -cfg 'https://mirrors.tuna.tsinghua.edu.cn/opensuse/update/leap/$releasever/non-oss/' mirror-update-non-oss;

RUN zypper ar -f -G https://download.opensuse.org/repositories/OBS:/Server:/Unstable/15.4/OBS:Server:Unstable.repo; \
  zypper -n install obs-api apache2 apache2-mod_xforward rubygem-passenger-apache2 memcached vim; zypper clean;

# setup obs-api configuration
RUN mv /etc/apache2/vhosts.d/obs.conf /etc/apache2/vhosts.d/obs.conf.bak; \
  mv /etc/sysconfig/apache2 /etc/sysconfig-apache2.bak; \
  mv /srv/www/obs/api/config/options.yml /srv/www/obs/api/config/options.yml.bak; \
  mv /srv/www/obs/api/config/database.yml /srv/www/obs/api/config/database.yml.bak; \
  sed -i "s#/ruby#/ruby.ruby3.1#g" /etc/apache2/conf.d/mod_passenger.conf; \
  mkdir -p /srv/obs/repos /run/passenger;

ADD config/obs.conf /etc/apache2/vhosts.d/obs.conf
ADD config/apache2 /etc/sysconfig/apache2
ADD config/options.yml /srv/www/obs/api/config/options.yml
ADD config/database.yml /srv/www/obs/api/config/database.yml
ADD config/certs/server.crt /srv/obs/certs/server.crt
ADD config/certs/server.key /srv/obs/certs/server.key

WORKDIR /srv/www/obs/api

VOLUME [ "/srv/www/obs/api/log/", "/var/cache/apache2/" ]

ADD entrypoint.sh /entrypoint.sh

CMD ["/bin/bash", "/entrypoint.sh"]
