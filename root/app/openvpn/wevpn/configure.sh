#!/bin/sh

VPN_COUNTRY=$1

if [ -z "$(find /cache/openvpn/wevpn/ -name "$VPN_COUNTRY\_*")" ] ; then
    log -e openvpn "No config files found for selected country. See https://hub.docker.com/r/rundqvist/openvpn for configuration."
    exit 1;
fi

log -d openvpn "Configuring WeVPN"
sleep 1
#
# Copy one config file as template
#
find /cache/openvpn/wevpn/ -name "$VPN_COUNTRY\_*" -print | head -1 | xargs -I '{}' cp {} /app/openvpn/config-$VPN_COUNTRY.ovpn
sleep 1
#
# Resolve remotes
#
find /cache/openvpn/wevpn/ -name "$VPN_COUNTRY\_*" -exec sed -n -e 's/^remote \(.*\) \(.*\)/\1/p' {} \; | sort > /app/openvpn/$VPN_COUNTRY-allowed.remotes
sleep 1
exit 0;
