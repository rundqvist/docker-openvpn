#!/bin/sh

if [ "$(var VPN_MULTIPLE)" = "true" ]
then
    log -v "Multiple vpn configured, skipping health check."
    echo "Multiple vpn. "
    exit 0;
fi

country=$(var VPN_COUNTRY)
ip=$(echoip -f https)
rc=$?

#
# Check if vpn is healthy.
#
if [ $rc -eq 0 ] && [ ! -z "$ip" ] && [ "$(var publicIp)" != "$ip" ]
then
    level="-v"
    if [ "$(var -k vpn.$country ip)" != "$ip" ]
    then
        level="-i"
    fi
    
    msg="Vpn ($country) ip: $ip"
    log $level openvpn "$msg."
    echo $msg

    var -k vpn.$country -d fail
    var -k vpn.$country ip "$ip"

    exit 0;
fi

#
# VPN is unhealthy
#
var -k vpn.$country fail + 1
var -k vpn.$country -d ip
publicIp="$(var publicIp)"

if [ $rc -eq 1 ] || [ -z "$ip" ]
then
    msg="Vpn ($country) ip check timed out"
elif [ "$publicIp" = "$ip" ]
then
    msg="Not connected to vpn ($country). Public ip: $ip";
else
    msg="Unknown error (rc: $rc, publicIp: $publicIp, vpnIp: $ip, country: $country)"
fi

count="$(var -k vpn.$country fail)"
log -e "$msg ($count)."
echo "$msg"

if [ "$count" == "3" ]
then
    var -k vpn.$country -d fail
    
    log -i "Restarting vpn ($country)."
    pid=$(ps -o pid,args | sed -n "/openvpn\/config-$country/p" | awk '{print $1}')

    kill -s SIGHUP $pid
fi

exit 1;
