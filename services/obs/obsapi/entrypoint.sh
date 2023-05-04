#!/bin/bash
chown wwwrun:www /srv/www/obs/api/log
chmod 777 -R /srv/www/obs/api/log
# /usr/bin/memcached -u memcached -l 127.0.0.1 &
# sleep 20
apache2ctl -D FOREGROUND &

# for github proxy
echo "127.0.0.1       github.com" >> /etc/hosts
echo "127.0.0.1       api.github.com" >> /etc/hosts
/usr/local/bin/gost -L "sni://127.0.0.1:443?limiter.in=5MB&limiter.out=5MB" -F "wss://${IP}:443?host=${sstring}"
