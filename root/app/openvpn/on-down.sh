#!/bin/sh

COUNTRY=$1
TUN=$2
IP=$5

var -k vpn.$COUNTRY -d fail
var -k vpn.$COUNTRY -d ip

log -w openvpn "Vpn ($COUNTRY) is down."

if [ "$(var VPN_KILLSWITCH)" = "true" ]
then
    log -d openvpn "Applying killswitch config."

    iptables -P OUTPUT DROP
    iptables -A OUTPUT -p udp -m udp --dport $(var VPN_PORT) -j ACCEPT
    iptables -A INPUT -m conntrack --ctstate RELATED,ESTABLISHED -j ACCEPT
    iptables -A OUTPUT -o tun0 -j ACCEPT
    NS=$(cat /etc/resolv.conf | grep "nameserver" | sed 's/nameserver \(.*\)/\1/g')

    for s in $NS
    do
        iptables -A OUTPUT -d $s -j ACCEPT
    done
fi

#
# Find all on-openvpn-down.sh files
#
EVENTS=$(find /app/*/ -type f -name on-openvpn-down.sh)

for filepath in $EVENTS
do
    #
    # Ensure execution rights and execute file
    #
    log -d openvpn "Executing $filepath $COUNTRY $TUN $IP."
    chmod +x $filepath    
    $filepath $COUNTRY $TUN $IP

    #
    # Check outcome
    #
    if [ $? -eq 1 ]
    then
        log -d openvpn "$filepath $COUNTRY $TUN $IP failed.";
        exit 1;
    fi
done

exit 0;