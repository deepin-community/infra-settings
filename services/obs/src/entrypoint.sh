#!/bin/bash
/usr/lib/obs/server/bs_redis --logfile log/redis.log &
/usr/lib/obs/server/bs_deltastore --logfile deltastore.log &
/usr/lib/obs/server/bs_service --logfile log/src_service.log &
/usr/lib/obs/server/bs_servicedispatch --logfile log/servicedispatch.log &
/usr/lib/obs/server/bs_srcserver --logfile log/src_server.log &
/usr/lib/obs/server/bs_sourcepublish --logfile log/sourcepublish.log
