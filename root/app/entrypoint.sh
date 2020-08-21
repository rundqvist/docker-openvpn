#!/bin/sh

/app/supervisor/init.sh
/app/openvpn/init.sh

exec supervisord -c /etc/supervisord.conf
