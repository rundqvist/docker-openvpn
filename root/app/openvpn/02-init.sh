#!/bin/sh

ERR=0
VPN_PROVIDER=$(var VPN_PROVIDER)
VPN_USERNAME=$(var VPN_USERNAME)
VPN_PASSWORD=$(var VPN_PASSWORD)
VPN_COUNTRY=$(var VPN_COUNTRY)
VPN_RANDOM_REMOTE=$(var VPN_RANDOM_REMOTE)
VPN_INCLUDED_REMOTES=$(var VPN_INCLUDED_REMOTES)
VPN_EXCLUDED_REMOTES=$(var VPN_EXCLUDED_REMOTES)

if [ -z "$VPN_PROVIDER" ] ; then
    log -w openvpn "VPN_PROVIDER is empty. No VPN is configured."
    exit 0;
elif [ ! -d "/app/openvpn/$VPN_PROVIDER" ] ; then
    log -e openvpn "VPN provider '$VPN_PROVIDER' is not supported. See https://hub.docker.com/r/rundqvist/openvpn for supported providers."
    exit 1;
fi

if [ -z "$VPN_USERNAME" ] ; then
    log -e openvpn "VPN_USERNAME is empty."
    ERR=1;
fi
if [ -z "$VPN_PASSWORD" ] ; then
    log -e openvpn "VPN_PASSWORD is empty."
    ERR=1;
fi
if [ -z "$VPN_COUNTRY" ] ; then
    log -e openvpn "VPN_COUNTRY is empty."
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
    log -e openvpn "Could not resolve IP."
    exit 1;
fi

log -i openvpn "Public IP is: $IP"
echo $RC":"$IP > /app/openvpn/ip

#
# Create auth file
#
echo "$VPN_USERNAME" > /app/openvpn/auth.conf
echo "$VPN_PASSWORD" >> /app/openvpn/auth.conf
chmod 600 /app/openvpn/auth.conf

chmod 755 /app/openvpn/$VPN_PROVIDER/configure.sh
chmod 755 /app/openvpn/$VPN_PROVIDER/setup.sh
chmod 755 /app/openvpn/tls-verify.sh
chmod 755 /app/openvpn/healthcheck.sh
chmod 755 /app/openvpn/on-up.sh
chmod 755 /app/openvpn/on-down.sh

> /app/openvpn/supervisord.conf

if [ $(echo $VPN_COUNTRY | wc -w) -gt 1 ] ; then
    log -i openvpn "Configuring multiple vpn."
    var VPN_MULTIPLE true
fi

if [ "$VPN_INCLUDED_REMOTES" != "" ]; then

    for s in $VPN_INCLUDED_REMOTES ; do
        echo $s
        log -d openvpn "Included remote: $s"
    done | sort > /app/openvpn/included.remotes
fi

if [ "$VPN_EXCLUDED_REMOTES" != "" ]; then

    for s in $VPN_EXCLUDED_REMOTES ; do
        echo $s
        log -d openvpn "Excluded remote: $s"
    done | sort > /app/openvpn/excluded.remotes  
fi

for country in $VPN_COUNTRY ; do

    #
    # Translate VPN_COUNTRY to ISO 3166-1 alpha-2 to avoid easily fixed common mistakes
    #
    if [ "$country" = "UK" ] ; then
        log -i openvpn "Country 'UK' is not ISO 3166-1 alpha-2. Translating to 'GB'."
        country="GB";
    fi

    log -i openvpn "Configuring $VPN_PROVIDER with '$country' tunnel"
    
    #
    # Update config
    #
    /app/openvpn/$VPN_PROVIDER/setup.sh

    #
    # Killswitch 
    #
    if [ "$(var VPN_KILLSWITCH)" = "true" ] ; then

        log -i openvpn "Killswitch enabled."

        iptables -P OUTPUT DROP
        iptables -A OUTPUT -p udp -m udp --dport $(var VPN_PORT) -j ACCEPT
        iptables -A INPUT -m conntrack --ctstate RELATED,ESTABLISHED -j ACCEPT
        iptables -A OUTPUT -o tun0 -j ACCEPT
        NS=$(cat /etc/resolv.conf | grep "nameserver" | sed 's/nameserver \(.*\)/\1/g')

        for s in $NS; do
            iptables -A OUTPUT -d $s -j ACCEPT
        done
    
    else

        log -w openvpn "Killswitch disabled."
    
    fi

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

    if [ -z "$(cat /app/openvpn/$country-allowed.remotes)" ] ; then
        log -e openvpn "Country $country has no remotes. "
    else
        sed "s/{VPN_COUNTRY}/$country/g" /app/openvpn/supervisord.template.conf >> /app/openvpn/supervisord.conf
        for remote in $(cat /app/openvpn/$country-allowed.remotes) ; do
            log -v openvpn "Allowed remote ($country): $remote"
        done
    fi
done
