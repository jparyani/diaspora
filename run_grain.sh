#!/bin/bash

set -e

cp -r /etc/service /tmp
test -d /var/log || cp -r /var_original/log /var
test -d /var/lib || cp -r /var_original/lib /var
test -d /var/run || cp -r /var_original/run /var
test -e /var/lock || ln -s /var/run/lock /var/lock
test -d /var/db || mkdir /var/db
test -e /var/app || cp -r /opt/app /var

exec /sbin/my_init
