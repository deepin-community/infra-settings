# https://github.com/openSUSE/docker-containers/blob/master/derived_images/systemd/Dockerfile
FROM hub.deepin.com/k3s/obs/apiv3:1.0.1

ENV container docker

# opensuse repository mirror settings
#RUN zypper mr -da; zypper ar -cfg 'https://mirrors.tuna.tsinghua.edu.cn/opensuse/distribution/leap/$releasever/repo/oss/' mirror-oss; \
#  zypper ar -cfg 'https://mirrors.tuna.tsinghua.edu.cn/opensuse/distribution/leap/$releasever/repo/non-oss/' mirror-non-oss; \
#  zypper ar -cfg 'https://mirrors.tuna.tsinghua.edu.cn/opensuse/update/leap/$releasever/oss/' mirror-update; \
#  zypper ar -cfg 'https://mirrors.tuna.tsinghua.edu.cn/opensuse/update/leap/$releasever/non-oss/' mirror-update-non-oss;
#
#RUN zypper ar -f -G https://download.opensuse.org/repositories/OBS:/Server:/2.10:/Staging/15.4/OBS:Server:2.10:Staging.repo; \
#  zypper -n install obs-api apache2 apache2-mod_xforward rubygem-passenger-apache2 memcached patch vim wget sudo gzip; zypper clean;
#
## setup github access proxy
#RUN cd /tmp && wget https://github.com/go-gost/gost/releases/download/v3.0.0-rc6/gost_3.0.0-rc6_linux_amd64.tar.gz && \
#tar xf gost_3.0.0-rc6_linux_amd64.tar.gz && install gost -m755 /usr/local/bin/gost && rm -f gost
#
## setup obs-api configuration
#RUN mkdir -p /srv/backup/; \
#  mv /etc/apache2/vhosts.d/obs.conf /srv/backup/obs.conf.bak; \
#  mv /etc/sysconfig/apache2 /srv/backup/sysconfig-apache2.bak; \
#  mv /srv/www/obs/api/config/options.yml /srv/backup/options.yml.bak; \
#  mv /srv/www/obs/api/config/database.yml /srv/backup/database.yml.bak; \
#  sed -i "s#/ruby#/ruby.ruby3.1#g" /etc/apache2/conf.d/mod_passenger.conf; \
#  mkdir -p /srv/obs/repos /run/passenger /patches;
#
#ADD api/config/obs.conf /etc/apache2/vhosts.d/obs.conf
#ADD api/config/apache2 /etc/sysconfig/apache2
#ADD api/config/options.yml /srv/www/obs/api/config/options.yml
#ADD api/config/database.yml /srv/www/obs/api/config/database.yml
RUN zypper -n install sudo; zypper clean;
ADD api/patches/0001-feat-add-topic.patch /patches/0001-feat-add-topic.patch
ADD api/patches/0002-feat-workflow-build-job-add-pending-status-support.patch /patches/0002-feat-workflow-build-job-add-pending-status-support.patch

#use some patches
#RUN patch -p0 /srv/www/obs/api/app/models/workflow/step.rb /patches/0001-feat-add-topic.patch
RUN patch -p3 -d /srv/www/obs/api/ < /patches/0002-feat-workflow-build-job-add-pending-status-support.patch

WORKDIR /srv/www/obs/api

VOLUME [ "/srv/www/obs/api/log/", "/var/cache/apache2/" ]

ADD api/entrypoint-online.sh /entrypoint.sh

CMD ["/bin/bash", "/entrypoint.sh"]
