#!/bin/sh

COUNTRY=$1
TUN=$2
IP=$5

log -i openvpn "Country: $COUNTRY is up."

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
    RC=$?

    if [ $RC -eq 1 ]; then
        log -e openvpn "$filepath $COUNTRY $TUN $IP failed";
        exit 1;
    fi
done

exit 0;