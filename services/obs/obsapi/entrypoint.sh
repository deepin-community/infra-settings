#!/bin/bash

/usr/bin/memcached -u memcached -l 127.0.0.1 &
sleep 6
apache2ctl -D FOREGROUND
