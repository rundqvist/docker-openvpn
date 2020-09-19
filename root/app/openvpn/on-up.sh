#!/bin/sh

COUNTRY=$1
TUN=$2
IP=$5

log -i openvpn "Country: $COUNTRY is up."

if [ "$(var VPN_KILLSWITCH)" = "true" ] ; then
    log -d openvpn "Removing killswitch config (since VPN is up)."

    iptables -P OUTPUT ACCEPT
    iptables -D OUTPUT -p udp -m udp --dport $(var VPN_PORT) -j ACCEPT
    iptables -D INPUT -m conntrack --ctstate RELATED,ESTABLISHED -j ACCEPT
    iptables -D OUTPUT -o tun0 -j ACCEPT
    NS=$(cat /etc/resolv.conf | grep "nameserver" | sed 's/nameserver \(.*\)/\1/g')

    for s in $NS; do
        iptables -D OUTPUT -d $s -j ACCEPT
    done
fi

#
# Find all on-openvpn-up.sh files
#
EVENTS=$(find /app/*/ -type f -name on-openvpn-up.sh)

for filepath in $EVENTS ; do

    #
    # Ensure execution rights and execute file
    #
    log -d openvpn "OnUp event. Executing $filepath $COUNTRY $TUN $IP"
    chmod +x $filepath    
    $filepath $COUNTRY $TUN $IP

    #
    # Check outcome
    #
    if [ $? -eq 1 ]; then
        log -d openvpn "$filepath $COUNTRY $TUN $IP failed";
        exit 1;
    fi
done

exit 0;