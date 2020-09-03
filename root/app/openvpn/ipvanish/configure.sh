#!/bin/sh

DATE_CURRENT=$(date +%d)
DATE_UPDATED=$(cat /cache/openvpn/ipvanish/date_updated 2>/dev/null)

VPN_INCLUDED_REMOTES=$(var VPN_INCLUDED_REMOTES)
VPN_EXCLUDED_REMOTES=$(var VPN_EXCLUDED_REMOTES)

if [ "$DATE_CURRENT" != "$DATE_UPDATED" ]; then

    log -i "Updating ipvanish config"

    mkdir -p /cache/openvpn/ipvanish
    rm -f /cache/openvpn/ipvanish/configs.zip

    wget -q https://www.ipvanish.com/software/configs/configs.zip -P /cache/openvpn/ipvanish/ 2>/dev/null
    RC=$?
    if [ $RC -eq 1 ]; then
        log -w "Failed to download new config"
    else

        log -i "Unzipping"
        unzip -q -o /cache/openvpn/ipvanish/configs.zip -d /cache/openvpn/ipvanish/

        echo $DATE_CURRENT > /cache/openvpn/ipvanish/date_updated
    fi
    
fi

if [ ! -f /app/openvpn/ca.ipvanish.com.crt ] ; then
    cp -f /cache/openvpn/ipvanish/ca.ipvanish.com.crt /app/openvpn/
fi

VPN_COUNTRY=$1
IPVANISH_COUNTRY=$1

if [ "$VPN_COUNTRY" = "GB" ] ; then
    IPVANISH_COUNTRY="UK";

    log -i "Parsing config files for 'UK' instead of 'GB' since IPVanish differs from ISO 3166-1 alpha-2"
fi

if [ -z "$(find /cache/openvpn/ipvanish/ -name "*-${IPVANISH_COUNTRY}-*")" ] ; then
    log -e "No config files found for selected country. See https://hub.docker.com/r/rundqvist/openvpn for configuration."
    exit 1;
fi

#
# Copy one config file as template
#
find /cache/openvpn/ipvanish/ -name "*-${IPVANISH_COUNTRY}-*" -print | head -1 | xargs -I '{}' cp {} /app/openvpn/config-$VPN_COUNTRY.ovpn

#
# Remove remote and verify-x509-name
#
sed -i '/verify-x509-name /d' /app/openvpn/config-$VPN_COUNTRY.ovpn

sed -i 's/^ca \(.*\)/ca \/app\/openvpn\/\1/g' /app/openvpn/config-$VPN_COUNTRY.ovpn
sed -i 's/^auth-user-pass/auth-user-pass \/app\/openvpn\/auth.conf/g' /app/openvpn/config-$VPN_COUNTRY.ovpn
echo "tls-verify '/app/openvpn/tls-verify.sh /app/openvpn/$VPN_COUNTRY-allowed.remotes'" >> /app/openvpn/config-$VPN_COUNTRY.ovpn
echo "mute-replay-warnings" >> /app/openvpn/config-$VPN_COUNTRY.ovpn

#
# Create list of allowed remotes
#
find /cache/openvpn/ipvanish/ -name "*${IPVANISH_COUNTRY}*" -exec sed -n -e 's/^remote \(.*\) \(.*\)/\1/p' {} \; | sort > /app/openvpn/$VPN_COUNTRY-allowed.remotes

if [ "$VPN_INCLUDED_REMOTES" != "" ]; then

    for s in $VPN_INCLUDED_REMOTES ; do
        echo $s
    done | sort > /app/openvpn/included.remotes

    comm /app/openvpn/$VPN_COUNTRY-allowed.remotes /app/openvpn/included.remotes -12 > /app/openvpn/tmp.remotes  
    rm -f /app/openvpn/included.remotes
    mv -f /app/openvpn/tmp.remotes /app/openvpn/$VPN_COUNTRY-allowed.remotes
    
fi

if [ "$VPN_EXCLUDED_REMOTES" != "" ]; then

    for s in $VPN_EXCLUDED_REMOTES ; do
        echo $s
    done | sort > /app/openvpn/excluded.remotes

    comm /app/openvpn/$VPN_COUNTRY-allowed.remotes /app/openvpn/excluded.remotes -23 > /app/openvpn/tmp.remotes  
    rm -f /app/openvpn/excluded.remotes
    mv -f /app/openvpn/tmp.remotes /app/openvpn/$VPN_COUNTRY-allowed.remotes
    
fi

#
#  Make sure list is not too long
#
echo "$(tail -n 32 /app/openvpn/$VPN_COUNTRY-allowed.remotes)" > /app/openvpn/$VPN_COUNTRY-allowed.remotes

#
# Add allowed remotes as remotes
#
sed -i '/remote /d' /app/openvpn/config-$VPN_COUNTRY.ovpn
echo "" >> /app/openvpn/config-$VPN_COUNTRY.ovpn
find /app/openvpn/ -name "$VPN_COUNTRY-allowed.remotes" -exec sed -n -e 's/^\(.*\)/remote \1 443/p' {} \; >> /app/openvpn/config-$VPN_COUNTRY.ovpn

exit 0;
