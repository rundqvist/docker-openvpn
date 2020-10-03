#!/bin/sh

if [ ! -f "/app/openvpn/provider/$VPN_PROVIDER.sh" ]
then
    log -e openvpn "VPN provider '$VPN_PROVIDER' is not supported. See https://hub.docker.com/r/rundqvist/openvpn for supported providers."
    exit 1;
fi

for var in "VPN_PROVIDER" "VPN_USERNAME" "VPN_PASSWORD" "VPN_COUNTRY"
do 
    if [ -z "$(var $var)" ]
    then
        log -e openvpn "Environment variable '$var' is mandatory. "
        var abort true
    else
        log -d openvpn "Mandatory variable '$var' is ok."
    fi
done

if [ "$(var abort)" = "true" ]
then
    exit 1;
fi

exit 0;
