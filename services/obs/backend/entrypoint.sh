#!/bin/bash
# Config wireguard ip, need kernel support it
set -x

for f in $(cd /etc/wireguard && ls)
do
    wg=$(echo "$f" |awk -F '.' '{ print $1}')
    wg-quick up $wg
done

# Add port forwarding
echo 1 > /proc/sys/net/ipv4/ip_forward
iptables -t nat -A PREROUTING -p tcp --dport $SRCPORT -j DNAT --to-destination $SRCIP:$SRCPORT
iptables -t nat -A POSTROUTING -d $SRCIP -p tcp --dport $SRCPORT -j SNAT --to-source $BACKENDIP

# Start obs backend services
/usr/lib/obs/server/bs_repserver --logfile rep_server.log &
/usr/lib/obs/server/bs_dispatch --logfile dispatcher.log &
/usr/lib/obs/server/bs_publish --logfile publisher.log &
/usr/lib/obs/server/bs_warden --logfile warden.log &
/usr/lib/obs/server/bs_dodup --logfile dodup.log &
/usr/lib/obs/server/bs_getbinariesproxy --logfile getbinariesproxy.log &
/usr/sbin/obsscheduler start
/usr/lib/obs/server/bs_notifyforward --logfile notifyforward.log

# For debug
while true;do sleep 6;done
