#!/bin/sh

VPN_COUNTRY=$1

VPN_INCLUDED_REMOTES=$(var VPN_INCLUDED_REMOTES)
VPN_EXCLUDED_REMOTES=$(var VPN_EXCLUDED_REMOTES)

if [ -z "$(find /cache/openvpn/wevpn/ -name "${VPN_COUNTRY}_*")" ] ; then
    log -e "No config files found for selected country. See https://hub.docker.com/r/rundqvist/openvpn for configuration."
    exit 1;
fi

#
# Copy one config file as template
#
find /cache/openvpn/wevpn/ -name "${VPN_COUNTRY}_*" -print | head -1 | xargs -I '{}' cp {} /app/openvpn/config-$VPN_COUNTRY.ovpn

#
# Add user.conf path
#
sed -i 's/^auth-user-pass/auth-user-pass \/app\/openvpn\/auth.conf/g' /app/openvpn/config-$VPN_COUNTRY.ovpn

#
# Resolve remotes
#
find /cache/openvpn/wevpn/ -name "${VPN_COUNTRY}_*" -exec sed -n -e 's/^remote \(.*\) \(.*\)/\1/p' {} \; | sort > /app/openvpn/$VPN_COUNTRY-allowed.remotes

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
# Add remotes
#
sed -i '/remote /d' /app/openvpn/config-$VPN_COUNTRY.ovpn
echo "" >> /app/openvpn/config-$VPN_COUNTRY.ovpn
find /app/openvpn/ -name "$VPN_COUNTRY-allowed.remotes" -exec sed -n -e 's/^\(.*\)/remote \1 1194/p' {} \; >> /app/openvpn/config-$VPN_COUNTRY.ovpn

exit 0;
