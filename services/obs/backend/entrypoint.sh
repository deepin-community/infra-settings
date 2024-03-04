#!/bin/bash
set -x

# link obs backends data directory
# /srv/obs-datas mount using separate storage, including backend repos\build\jobs directory
rm -rf /srv/obs
mkdir -p /srv/obs-datas/$(hostname) && ln -s /srv/obs-datas/$(hostname) /srv/obs
ln -sf /srv/configuration.xml /srv/obs/configuration.xml
chown obsrun:obsrun /srv/obs-datas/$(hostname) /srv/obs

# Start obs backend services
starting() {
    /usr/lib/obs/server/bs_repserver --logfile rep_server.log &
    /usr/lib/obs/server/bs_dispatch --logfile dispatcher.log &
    /usr/lib/obs/server/bs_publish --logfile publisher.log &
    /usr/lib/obs/server/bs_warden --logfile warden.log &
    /usr/lib/obs/server/bs_dodup --logfile dodup.log &
    /usr/lib/obs/server/bs_getbinariesproxy --logfile getbinariesproxy.log &
    /usr/sbin/obsscheduler start
    /usr/lib/obs/server/bs_notifyforward --logfile notifyforward.log
}

stop() {
    ps -ef |grep bs_ |awk '{print $2}' |xargs kill -9 || true
    rm -f /srv/obs/run/*.lock
    # Clean down workers
    rm -f /srv/obs/workers/down/*
}

# For auto restart
/usr/sbin/logrotate /etc/logrotate.conf
cron -n &
while true
do
    starting
    stop
    sleep 6
done
