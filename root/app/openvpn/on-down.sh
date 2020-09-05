#!/bin/sh

COUNTRY=$1
TUN=$2
IP=$5

log -i "[OpenVPN] Country: $COUNTRY is down."

#
# Find all on-openvpn-down.sh files
#
EVENTS=$(find /app/*/ -type f -name on-openvpn-down.sh)

for filepath in $EVENTS ; do

    #
    # Ensure execution rights and execute file
    #
    log -d "[OpenVPN] OnDown event. Executing $filepath $COUNTRY $TUN $IP"
    chmod +x $filepath    
    $filepath $COUNTRY $TUN $IP

    #
    # Check outcome
    #
    RC=$?

    if [ $RC -eq 1 ]; then
        log -e "[OpenVPN] $filepath $COUNTRY $TUN $IP failed";
        exit 1;
    fi
done

exit 0;