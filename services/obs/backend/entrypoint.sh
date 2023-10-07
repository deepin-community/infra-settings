#!/bin/bash
# Config wireguard ip, need kernel support it
set -x

for f in $(cd /etc/wireguard && ls)
do
    wg=$(echo "$f" |awk -F '.' '{ print $1}')
    wg-quick up $wg
done

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
