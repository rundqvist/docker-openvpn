#!/bin/sh

if [ "$(var VPN_MULTIPLE)" = "true" ]
then
    log -v openvpn "[health] Health check (Multiple VPN)."
    echo "Multiple VPN. "
    exit 0;
fi

log -v openvpn "[health] Check health"

VPNIP=$(wget http://api.ipify.org -T 10 -O - -q 2>/dev/null)

if [ $? -eq 1 ]
then
    var fail + 1
    log -e openvpn "[health] No internet connection ($(var fail))."
    echo "No internet connection ($(var fail))."
elif [ "$(var publicIp)" = "$VPNIP" ]
then
    var fail + 1
    log -e openvpn "[health] Not connected to VPN. Public IP is: $VPNIP ($(var fail)).";
	echo "Not connected to VPN. Public IP is: $VPNIP ($(var fail)).";
else
    var -d fail
    log -v openvpn "[health] VPN IP is: $VPNIP."
    echo "VPN IP: $VPNIP. ";
fi

if [ "$(var fail)" = "3" ]
then
    var -d fail
    country=$(var VPN_COUNTRY)
    log -i openvpn "[health] Restarting VPN."
    pid=$(ps -o pid,args | sed -n "/openvpn\/config-$country/p" | awk '{print $1}')

    kill -s SIGHUP $pid

elif [ -z "$(var fail)" ]; then
    exit 0;
fi

exit 1;
