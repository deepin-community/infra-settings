#!/bin/bash
set -x

# link obs data directory for build and publish
# /srv/obs-build-repos mount using separate storage, including the repos\build\jobs directory
mkdir -p /srv/obs-build-repos/repos && ln -sf /srv/obs-build-repos/repos /srv/obs/repos
mkdir -p /srv/obs-build-repos/repos && ln -sf /srv/obs-build-repos/build /srv/obs/build
mkdir -p /srv/obs-build-repos/jobs && ln -sf /srv/obs-build-repos/jobs /srv/obs/jobs
chown -R obsrun:obsrun /srv/obs-build-repos /srv/obs/build /srv/obs/jobs /srv/obs/repos

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
