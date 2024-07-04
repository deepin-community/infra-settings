#!/bin/bash
set -x

# prepare ssh key for git ssh clone
mkdir -p /home/obsservicerun/.ssh
chown obsservicerun:obsservicerun -R /home/obsservicerun
chmod 700 -R /home/obsservicerun
usermod -d /home/obsservicerun obsservicerun
cp /home/obs_ed25519 /home/obsservicerun/.ssh/id_ed25519 && chmod 400 /home/obsservicerun/.ssh/id_ed25519 || true
cp /home/known_hosts /home/obsservicerun/.ssh/known_hosts && chmod 600 /home/obsservicerun/.ssh/known_hosts || true
chown obsservicerun:obsservicerun -R /home/obsservicerun

cp /srv/obs/_configuration.xml /srv/obs/configuration.xml

starting() {
    /usr/lib/obs/server/bs_redis --logfile log/redis.log &
    /usr/lib/obs/server/bs_deltastore --logfile deltastore.log &
    /usr/lib/obs/server/bs_service --logfile log/src_service.log &
    /usr/lib/obs/server/bs_servicedispatch --logfile log/servicedispatch.log &
    /usr/lib/obs/server/bs_srcserver --logfile log/src_server.log &
    /usr/lib/obs/server/bs_sourcepublish --logfile log/sourcepublish.log
}

stop() {
    ps -ef |grep bs_ |awk '{print $2}' |xargs kill -9 || true
    rm -f /srv/obs/run/*.lock
}

# For auto restart
while true
do
    starting
    stop
    sleep 6
done
