#!/bin/sh

provider=$(var VPN_PROVIDER)
COUNTRY=$1
TUN=$2
IP=$5

if [ "$(var VPN_KILLSWITCH)" = "true" ]
then
    log -d openvpn "Removing killswitch config."

    iptables -P OUTPUT ACCEPT
    iptables -D OUTPUT -p udp -m udp --dport $(var VPN_PORT) -j ACCEPT
    iptables -D INPUT -m conntrack --ctstate RELATED,ESTABLISHED -j ACCEPT
    iptables -D OUTPUT -o tun0 -j ACCEPT
    NS=$(cat /etc/resolv.conf | grep "nameserver" | sed 's/nameserver \(.*\)/\1/g')

    for s in $NS
    do
        iptables -D OUTPUT -d $s -j ACCEPT
    done
fi

host=$(/app/openvpn/provider/$provider.sh -e host -c $COUNTRY)

log -i openvpn "Vpn ($COUNTRY) is up. Connected remote: $host."

#
# Find all on-openvpn-up.sh files
#
EVENTS=$(find /app/*/ -type f -name on-openvpn-up.sh)

for filepath in $EVENTS
do
    #
    # Ensure execution rights and execute file
    #
    log -v openvpn "Executing $filepath $COUNTRY $TUN $IP."
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