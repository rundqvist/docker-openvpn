#!/bin/sh

#
# Copy one config file as template
#
find /cache/openvpn/wevpn/ -name "${VPN_COUNTRY}_*" -print | head -1 | xargs -I '{}' cp {} /app/openvpn/config.ovpn

#
# Add user.config path
#
sed -i 's/^auth-user-pass/auth-user-pass \/app\/openvpn\/auth.conf/g' /app/openvpn/config.ovpn

#
# Resolve remotes
#
find /cache/openvpn/wevpn/ -name "${VPN_COUNTRY}_*" -exec sed -n -e 's/^remote \(.*\) \(.*\)/\1/p' {} \; | sort > /app/openvpn/allowed.remotes

if [ $INCLUDED_REMOTES != '' ]; then

    for s in $INCLUDED_REMOTES ; do
        echo $s
    done | sort > /app/openvpn/included.remotes

    comm /app/openvpn/allowed.remotes /app/openvpn/included.remotes -12 > /app/openvpn/tmp.remotes  
    rm -f /app/openvpn/included.remotes
    mv -f /app/openvpn/tmp.remotes /app/openvpn/allowed.remotes
    
fi

if [ $EXCLUDED_REMOTES != '' ]; then

    for s in $EXCLUDED_REMOTES ; do
        echo $s
    done | sort > /app/openvpn/excluded.remotes

    comm /app/openvpn/allowed.remotes /app/openvpn/excluded.remotes -23 > /app/openvpn/tmp.remotes  
    rm -f /app/openvpn/excluded.remotes
    mv -f /app/openvpn/tmp.remotes /app/openvpn/allowed.remotes
    
fi

#
# Add remotes
#
sed -i '/remote /d' /app/openvpn/config.ovpn
echo "" >> /app/openvpn/config.ovpn
find /app/openvpn/ -name "allowed.remotes" -exec sed -n -e 's/^\(.*\)/remote \1 1194/p' {} \; >> /app/openvpn/config.ovpn

#
# Random remote
#
if [ "$VPN_RANDOM_REMOTE" = "true" ]; then
	echo 'remote-random' >> /app/openvpn/config.ovpn
fi