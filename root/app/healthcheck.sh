#!/bin/sh

if [ $VPN_PROVIDER != '' ]; then

    /app/openvpn/healthcheck.sh

fi
