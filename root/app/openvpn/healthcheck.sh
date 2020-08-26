#!/bin/sh

if [ -z "$VPN_PROVIDER" ]; then

    echo "No VPN provider specified."
    exit 1;

fi

if [ -f /app/openvpn/multiple ]; then

    echo "Multiple VPN configured."
    exit 0;
fi

VPNIP=$(wget http://api.ipify.org -O - -q 2>/dev/null)
RC=$?
IP=$(cat /app/openvpn/ip)

if [ $RC -eq 1 ]; then
    echo "No internet connection."
    exit 1;
elif [[ ${IP:0:1} = "1" ]]; then
    echo "IP could not be resolved before connecting to VPN. Privacy could be compromized. Public IP is: $VPNIP."
    exit 1;
elif [ $RC":"$VPNIP = $IP ]; then
	echo "Not connected to VPN. Public IP is: $VPNIP.";
	exit 1;
fi

echo "Public IP is: $VPNIP. ";

exit 0;
