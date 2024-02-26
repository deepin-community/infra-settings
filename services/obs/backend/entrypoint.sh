#!/bin/bash
set -x

# link obs data directory for build and publish
# /srv/obs-datas mount using separate storage, including the repos\build\jobs directory
mkdir -p /srv/obs-datas/repos && if [ ! -d "/srv/obs/repos" ];then ln -sf /srv/obs-datas/repos /srv/obs/repos;fi
mkdir -p /srv/obs-datas/build && if [ ! -d "/srv/obs/build" ];then ln -sf /srv/obs-datas/build /srv/obs/build;fi
mkdir -p /srv/obs-datas/jobs/$(hostname) && if [ ! -d "/srv/obs/jobs" ];then ln -s /srv/obs-datas/jobs/$(hostname) /srv/obs/jobs;fi
chown -R obsrun:obsrun /srv/obs/jobs /srv/obs-datas/jobs/$(hostname)

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
while true
do
    starting
    stop
    sleep 6
done
