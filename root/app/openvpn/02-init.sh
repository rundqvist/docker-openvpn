#!/bin/sh

ERR=0
VPN_PROVIDER=$(var VPN_PROVIDER)
VPN_USERNAME=$(var VPN_USERNAME)
VPN_PASSWORD=$(var VPN_PASSWORD)
VPN_COUNTRY=$(var VPN_COUNTRY)
VPN_RANDOM_REMOTE=$(var VPN_RANDOM_REMOTE)

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
chmod 755 /app/openvpn/on-up.sh
chmod 755 /app/openvpn/on-down.sh

> /app/openvpn/supervisord.conf

if [ $(echo $VPN_COUNTRY | wc -w) -gt 1 ] ; then
    log -i "Configuring multiple vpn."
    var VPN_MULTIPLE true
fi

for country in $VPN_COUNTRY ; do

    #
    # Translate VPN_COUNTRY to ISO 3166-1 alpha-2 to avoid easily fixed common mistakes
    #
    if [ "$country" = "UK" ] ; then
        log -i "Country 'UK' is not ISO 3166-1 alpha-2. Translating to 'GB'."
        country="GB";
    fi

    log -i "Configuring $VPN_PROVIDER with '$country' tunnel"
    
    #
    # Provider specific configuration
    #
    /app/openvpn/$VPN_PROVIDER/configure.sh $country

    #
    # Random remote
    #
    if [ "$VPN_RANDOM_REMOTE" = "true" ]; then
        echo 'remote-random' >> /app/openvpn/config-$country.ovpn
    fi

    if [ "$(var VPN_MULTIPLE)" = "true" ]; then
        echo 'route-noexec' >> /app/openvpn/config-$country.ovpn
    fi

    sed "s/{VPN_COUNTRY}/$country/g" /app/openvpn/supervisord.template.conf >> /app/openvpn/supervisord.conf

    for remote in $(cat /app/openvpn/$country-allowed.remotes) ; do
        log -v "Allowed remote ($country): $remote"
    done

done
