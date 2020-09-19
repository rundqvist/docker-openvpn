#!/bin/sh

VPN_PROVIDER=$(var VPN_PROVIDER)
VPN_USERNAME=$(var VPN_USERNAME)
VPN_PASSWORD=$(var VPN_PASSWORD)
VPN_COUNTRY=$(var VPN_COUNTRY)
VPN_RANDOM_REMOTE=$(var VPN_RANDOM_REMOTE)
VPN_INCLUDED_REMOTES=$(var VPN_INCLUDED_REMOTES)
VPN_EXCLUDED_REMOTES=$(var VPN_EXCLUDED_REMOTES)

#
# Store host ip before starting vpn
#
publicIp=$(wget http://api.ipify.org -T 10 -O - -q 2>/dev/null)

if [ $? -eq 1 ] ; then
    log -e openvpn "Could not resolve IP."
    exit 1;
fi

log -i openvpn "Public IP is: $publicIp"
var publicIp "$publicIp"

#
# Create auth file
#
echo "$VPN_USERNAME" > /app/openvpn/auth.conf
echo "$VPN_PASSWORD" >> /app/openvpn/auth.conf
chmod 600 /app/openvpn/auth.conf

chmod 755 /app/openvpn/$VPN_PROVIDER/update.sh
chmod 755 /app/openvpn/$VPN_PROVIDER/configure.sh
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
    /app/openvpn/$VPN_PROVIDER/update.sh

    #
    # Killswitch 
    #
    if [ "$(var VPN_MULTIPLE)" = "true" ] ; then
        if [ "$(var VPN_KILLSWITCH)" = "true" ] ; then
            log -i openvpn "Killswitch not possible with multiple VPN configured. Disabling."
            var VPN_KILLSWITCH false
        fi
    else
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
    fi

    #
    # Provider specific configuration
    #
    /app/openvpn/$VPN_PROVIDER/configure.sh $country

    if [ $? -eq 1 ]
    then
        if [ "$(var VPN_MULTIPLE)" = "true" ]
        then
            continue
        else
            exit 1;
        fi
    fi

    #
    # Add user.conf path
    #
    sed -i 's/^auth-user-pass/auth-user-pass \/app\/openvpn\/auth.conf/g' /app/openvpn/config-$country.ovpn

    if [ -f /app/openvpn/included.remotes ]; then
        comm /app/openvpn/$country-allowed.remotes /app/openvpn/included.remotes -12 > /app/openvpn/$country-tmp.remotes
        mv -f /app/openvpn/$country-tmp.remotes /app/openvpn/$country-allowed.remotes 
    fi

    if [ -f /app/openvpn/excluded.remotes ]; then
        comm /app/openvpn/$country-allowed.remotes /app/openvpn/excluded.remotes -23 > /app/openvpn/$country-tmp.remotes 
        mv -f /app/openvpn/$country-tmp.remotes /app/openvpn/$country-allowed.remotes
    fi

    #
    #  Make sure list is not too long
    #
    echo "$(tail -n 32 /app/openvpn/$country-allowed.remotes)" > /app/openvpn/$country-allowed.remotes

    #
    # Add allowed remotes as remotes
    #
    sed -i '/remote /d' /app/openvpn/config-$country.ovpn
    echo "" >> /app/openvpn/config-$country.ovpn
    find /app/openvpn/ -name "$country-allowed.remotes" -exec sed -n -e "s/^\(.*\)/remote \1 $(var VPN_PORT)/p" {} \; >> /app/openvpn/config-$country.ovpn


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
