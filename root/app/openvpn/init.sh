#!/bin/sh

ERR=0

if [ -z "$VPN_PROVIDER" ] ; then
    echo "[WAR] VPN_PROVIDER is empty. No VPN is configured." >> /proc/1/fd/1;
    exit 0;
fi

if [ -z "$VPN_USERNAME" ] ; then
    echo "[ERR] VPN_USERNAME is empty." >> /proc/1/fd/1;
    ERR=1;
fi
if [ -z "$VPN_PASSWORD" ] ; then
    echo "[ERR] VPN_PASSWORD is empty." >> /proc/1/fd/1;
    ERR=1;
fi
if [ -z "$VPN_COUNTRY" ] ; then
    echo "[ERR] VPN_COUNTRY is empty." >> /proc/1/fd/1;
    ERR=1;
fi

if [ $ERR = 1 ] ; then
    exit 1;
fi

#
# Store host ip before starting vpn
#
HOSTIP=$(wget http://api.ipify.org -O - -q)
RC=$?
if [ $RC = 1 ] ; then
    echo "[ERR] Could not resolve host IP." >> /proc/1/fd/1;
    exit 1;
fi

echo $RC":"$HOSTIP > /app/openvpn/hostip

#
# Create auth file
#
echo "$VPN_USERNAME" > /app/openvpn/auth.conf
echo "$VPN_PASSWORD" >> /app/openvpn/auth.conf
chmod 600 /app/openvpn/auth.conf

chmod 755 /app/openvpn/$VPN_PROVIDER/configure.sh
chmod 755 /app/openvpn/tls-verify.sh
chmod 755 /app/openvpn/healthcheck.sh

/app/openvpn/$VPN_PROVIDER/configure.sh

cat /app/openvpn/supervisord.conf >> /etc/supervisord.conf
