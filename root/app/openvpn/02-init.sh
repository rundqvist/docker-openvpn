#!/bin/sh

ERR=0

if [ -z "$VPN_PROVIDER" ] ; then
    log -w "VPN_PROVIDER is empty. No VPN is configured."
    exit 0;
elif [ ! -d "/app/openvpn/$VPN_PROVIDER" ] ; then
    log -e "VPN provider '$VPN_PROVIDER' is not supported. See https://hub.docker.com/r/rundqvist/openvpn for supported providers."
    exit 1;
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
# Translate VPN_COUNTRY to ISO 3166-1 alpha-2 to avoid easily fixed common mistakes
#
if [ "$VPN_COUNTRY" = "UK" ] ; then
    log -i "Country 'UK' is not ISO 3166-1 alpha-2. Translating to 'GB'."
    export VPN_COUNTRY="GB";
fi

#
# Store host ip before starting vpn
#
IP=$(wget http://api.ipify.org -O - -q 2>/dev/null)
RC=$?
if [ $RC = 1 ] ; then
    log -e "Could not resolve IP."
    exit 1;
fi

log -i "Public IP is: $IP"
echo $RC":"$IP > /app/openvpn/ip

#
# Create auth file
#
echo "$VPN_USERNAME" > /app/openvpn/auth.conf
echo "$VPN_PASSWORD" >> /app/openvpn/auth.conf
chmod 600 /app/openvpn/auth.conf

chmod 755 /app/openvpn/$VPN_PROVIDER/configure.sh
chmod 755 /app/openvpn/tls-verify.sh
chmod 755 /app/openvpn/healthcheck.sh

log -i "Configuring $VPN_PROVIDER (selected country is '$VPN_COUNTRY')"
/app/openvpn/$VPN_PROVIDER/configure.sh
