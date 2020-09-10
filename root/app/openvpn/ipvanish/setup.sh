#!/bin/sh

var VPN_PORT 443

DATE_CURRENT=$(date +%d)
DATE_UPDATED=$(cat /cache/openvpn/ipvanish/date_updated 2>/dev/null)

if [ "$DATE_CURRENT" != "$DATE_UPDATED" ]; then

    log -i openvpn "Updating ipvanish config"

    mkdir -p /cache/openvpn/ipvanish
    rm -f /cache/openvpn/ipvanish/configs.zip

    wget -q https://www.ipvanish.com/software/configs/configs.zip -P /cache/openvpn/ipvanish/ 2>/dev/null
    RC=$?
    if [ $RC -eq 1 ]; then
        log -w openvpn "Failed to download new config"
    else

        log -i openvpn "Unzipping"
        unzip -q -o /cache/openvpn/ipvanish/configs.zip -d /cache/openvpn/ipvanish/

        echo $DATE_CURRENT > /cache/openvpn/ipvanish/date_updated
    fi
    
fi

if [ ! -f /app/openvpn/ca.ipvanish.com.crt ] ; then
    cp -f /cache/openvpn/ipvanish/ca.ipvanish.com.crt /app/openvpn/
fi
