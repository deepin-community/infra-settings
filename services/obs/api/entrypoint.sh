#!/bin/bash
# obs db config
#export RAILS_ENV=production
#sudo -E ./bin/rake db:setup
#sudo -E ./bin/rake writeconfiguration

chown -R wwwrun:www /srv/www/obs/api/log
chmod 777 -R /srv/www/obs/api/log
# /usr/bin/memcached -u memcached -l 127.0.0.1 &
# sleep 20

apache2ctl -D FOREGROUND &
RAILS_ENV=production sudo -E -u wwwrun /usr/bin/bundle.ruby3.1 exec script/delayed_job.api.rb --queue=default start -i 1030
RAILS_ENV=production sudo -E -u wwwrun /usr/bin/bundle.ruby3.1 exec script/delayed_job.api.rb --queue=quick start -i 0
RAILS_ENV=production sudo -E -u wwwrun /usr/bin/bundle.ruby3.1 exec script/delayed_job.api.rb --queue=quick start -i 1
RAILS_ENV=production sudo -E -u wwwrun /usr/bin/bundle.ruby3.1 exec script/delayed_job.api.rb --queue=quick start -i 2
RAILS_ENV=production sudo -E -u wwwrun /usr/bin/bundle.ruby3.1 exec script/delayed_job.api.rb --queue=scm start -i 1070
RAILS_ENV=production sudo -E -u wwwrun /usr/bin/bundle.ruby3.1 exec script/delayed_job.api.rb --queue=project_log_rotate start -i 1040
RAILS_ENV=production sudo -E -u wwwrun /usr/bin/bundle.ruby3.1 exec script/delayed_job.api.rb --queue=staging start -i 1060
RAILS_ENV=production sudo -E -u wwwrun /usr/bin/bundle.ruby3.1 exec script/delayed_job.api.rb --queue=consistency_check start -i 1050
RAILS_ENV=production sudo -E -u wwwrun /usr/bin/bundle.ruby3.1 exec script/delayed_job.api.rb --queue=releasetracking start -i 1000
RAILS_ENV=production sudo -E -u wwwrun /srv/www/obs/api/bin/clockworkd --log-dir=log -l -c config/clock.rb start

RAILS_ENV=production /srv/www/obs/api/bin/rails sphinx:start &

# for github proxy
echo "127.0.0.1       github.com" >> /etc/hosts
echo "127.0.0.1       api.github.com" >> /etc/hosts
echo "127.0.0.1       raw.githubusercontent.com" >> /etc/hosts
/usr/local/bin/gost -L "sni://127.0.0.1:443?limiter.in=5MB&limiter.out=5MB" -F "wss://${IP}:443?host=${sstring}"
