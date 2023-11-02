#!/bin/bash

# 修改hostname,使其包含obs 节点的名称
OLDNAME=$(hostname)
HOSTSUFFIX=$(hostname |awk -F '-' '{print $3"-"$5"-"$6}')
export HOSTNAME="$NODENAME-$HOSTSUFFIX"
echo "$HOSTNAME" > /proc/sys/kernel/hostname
echo "$HOSTNAME" > /etc/hostname
sed "s/$OLDNAME/$HOSTNAME/g" /etc/hosts >> /etc/hosts
echo "Worker hostname: $HOSTNAME"
/usr/sbin/obsworker start
while true;do sleep 6;done
