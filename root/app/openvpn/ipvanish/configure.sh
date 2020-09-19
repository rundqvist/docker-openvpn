#!/bin/sh

VPN_COUNTRY=$1
IPVANISH_COUNTRY=$1

if [ "$VPN_COUNTRY" = "GB" ] ; then
    IPVANISH_COUNTRY="UK";

    log -d openvpn "Parsing config files for 'UK' instead of 'GB' since IPVanish differs from ISO 3166-1 alpha-2"
fi

if [ -z "$(find /cache/openvpn/ipvanish/ -name "*-$IPVANISH_COUNTRY-*")" ] ; then
    log -e openvpn "No config files found country $VPN_COUNTRY. Ignoring. "
    exit 1;
fi

#
# Copy one config file as template
#
find /cache/openvpn/ipvanish/ -name "*-$IPVANISH_COUNTRY-*" -print | head -1 | xargs -I '{}' cp {} /app/openvpn/config-$VPN_COUNTRY.ovpn

#
# Remove verify-x509-name and add tls-verify and cert path
#
sed -i '/verify-x509-name /d' /app/openvpn/config-$VPN_COUNTRY.ovpn
echo "tls-verify '/app/openvpn/tls-verify.sh /app/openvpn/$VPN_COUNTRY-allowed.remotes'" >> /app/openvpn/config-$VPN_COUNTRY.ovpn
sed -i 's/^ca \(.*\)/ca \/app\/openvpn\/\1/g' /app/openvpn/config-$VPN_COUNTRY.ovpn

#
# Mute replay warnings
# 
echo "mute-replay-warnings" >> /app/openvpn/config-$VPN_COUNTRY.ovpn

#
# Resolve remotes
#
find /cache/openvpn/ipvanish/ -name "*-$IPVANISH_COUNTRY-*" -exec sed -n -e 's/^remote \(.*\) \(.*\)/\1/p' {} \; | sort > /app/openvpn/$VPN_COUNTRY-allowed.remotes

exit 0;
