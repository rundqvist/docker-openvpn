#!/bin/sh

ERR=0

if [ -z "$VPN_PROVIDER" ] ; then
    log -w "VPN_PROVIDER is empty. No VPN is configured."
    exit 0;
fi

if [ -z "$VPN_USERNAME" ] ; then
    log -e "VPN_USERNAME is empty."
    ERR=1;
fi
if [ -z "$VPN_PASSWORD" ] ; then
    log -e "VPN_PASSWORD is empty."
    ERR=1;
fi
if [ -z "$VPN_COUNTRY" ] ; then
    log -e "VPN_COUNTRY is empty."
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
    log -e "Could not resolve host IP."
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

log -i "Configuring $VPN_PROVIDER"
/app/openvpn/$VPN_PROVIDER/configure.sh
