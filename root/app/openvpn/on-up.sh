#!/bin/sh

COUNTRY=$1
TUN=$2
IP=$5

#
# Find all on-openvpn-up.sh files
#
EVENTS=$(find /app/*/ -type f -name on-openvpn-up.sh)

for filepath in $EVENTS ; do

    #
    # Ensure execution rights and execute file
    #
    chmod +x $filepath    
    $filepath $COUNTRY $TUN $IP

    #
    # Check outcome
    #
    RC=$?

    if [ $RC -eq 1 ]; then
        log -e "Event $filepath $COUNTRY $TUN $IP failed";
        exit 1;
    fi
done

exit 0;