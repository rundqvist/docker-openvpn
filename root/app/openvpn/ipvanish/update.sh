#!/bin/sh

var VPN_PORT 443

DATE_CURRENT=$(date +%d)
DATE_UPDATED=$(cat /cache/openvpn/ipvanish/date_updated 2>/dev/null)

if [ "$DATE_CURRENT" != "$DATE_UPDATED" ]; then

    log -i openvpn "Downloading new config."

    mkdir -p /cache/openvpn/ipvanish
    rm -f /cache/openvpn/ipvanish/configs.zip

    wget -q https://www.ipvanish.com/software/configs/configs.zip -P /cache/openvpn/ipvanish/ 2>/dev/null
    RC=$?
    if [ $RC -eq 1 ]; then
        log -w openvpn "Download failed. "
    else

        log -d openvpn "Unzipping configs..."
        unzip -q -o /cache/openvpn/ipvanish/configs.zip -d /cache/openvpn/ipvanish/

        echo $DATE_CURRENT > /cache/openvpn/ipvanish/date_updated
    fi
else
    log -i openvpn "Config recently updated. Skipping..."
fi

if [ ! -f /app/openvpn/ca.ipvanish.com.crt ] ; then
    log -d openvpn "Copying certificate."
    cp -f /cache/openvpn/ipvanish/ca.ipvanish.com.crt /app/openvpn/
fi
