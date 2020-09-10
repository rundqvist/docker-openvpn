#!/bin/sh

VPN_COUNTRY=$1
IPVANISH_COUNTRY=$1

VPN_INCLUDED_REMOTES=$(var VPN_INCLUDED_REMOTES)
VPN_EXCLUDED_REMOTES=$(var VPN_EXCLUDED_REMOTES)

if [ "$VPN_COUNTRY" = "GB" ] ; then
    IPVANISH_COUNTRY="UK";

    log -i openvpn "Parsing config files for 'UK' instead of 'GB' since IPVanish differs from ISO 3166-1 alpha-2"
fi

if [ -z "$(find /cache/openvpn/ipvanish/ -name "*-$IPVANISH_COUNTRY-*")" ] ; then
    log -e openvpn "No config files found for selected country. See https://hub.docker.com/r/rundqvist/openvpn for configuration."
    exit 1;
fi

#
# Copy one config file as template
#
find /cache/openvpn/ipvanish/ -name "*-$IPVANISH_COUNTRY-*" -print | head -1 | xargs -I '{}' cp {} /app/openvpn/config-$VPN_COUNTRY.ovpn

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
find /cache/openvpn/ipvanish/ -name "*-$IPVANISH_COUNTRY-*" -exec sed -n -e 's/^remote \(.*\) \(.*\)/\1/p' {} \; | sort > /app/openvpn/$VPN_COUNTRY-allowed.remotes

if [ -f /app/openvpn/included.remotes ]; then
    comm /app/openvpn/$VPN_COUNTRY-allowed.remotes /app/openvpn/included.remotes -12 > /app/openvpn/$VPN_COUNTRY-tmp.remotes
    mv -f /app/openvpn/$VPN_COUNTRY-tmp.remotes /app/openvpn/$VPN_COUNTRY-allowed.remotes 
fi

if [ -f /app/openvpn/excluded.remotes ]; then
    comm /app/openvpn/$VPN_COUNTRY-allowed.remotes /app/openvpn/excluded.remotes -23 > /app/openvpn/$VPN_COUNTRY-tmp.remotes 
    mv -f /app/openvpn/$VPN_COUNTRY-tmp.remotes /app/openvpn/$VPN_COUNTRY-allowed.remotes
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
