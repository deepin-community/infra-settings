#!/bin/bash
/usr/lib/obs/server/bs_repserver --logfile rep_server.log &
/usr/lib/obs/server/bs_dispatch --logfile dispatcher.log &
/usr/lib/obs/server/bs_publish --logfile publisher.log &
/usr/lib/obs/server/bs_warden --logfile warden.log &
/usr/lib/obs/server/bs_dodup --logfile dodup.log &
/usr/lib/obs/server/bs_getbinariesproxy --logfile getbinariesproxy.log &
/usr/sbin/obsscheduler start
/usr/lib/obs/server/bs_notifyforward --logfile notifyforward.log
