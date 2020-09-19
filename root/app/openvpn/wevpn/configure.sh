#!/bin/sh

VPN_COUNTRY=$1

if [ -z "$(find /cache/openvpn/wevpn/ -name "$VPN_COUNTRY\_*")" ] ; then
    log -e openvpn "No config files found country $VPN_COUNTRY. Ignoring. "
    exit 1;
fi

#
# Copy one config file as template
#
find /cache/openvpn/wevpn/ -name "$VPN_COUNTRY\_*" -print | head -1 | xargs -I '{}' cp {} /app/openvpn/config-$VPN_COUNTRY.ovpn

#
# Resolve remotes
#
find /cache/openvpn/wevpn/ -name "$VPN_COUNTRY\_*" -exec sed -n -e 's/^remote \(.*\) \(.*\)/\1/p' {} \; | sort > /app/openvpn/$VPN_COUNTRY-allowed.remotes

exit 0;
