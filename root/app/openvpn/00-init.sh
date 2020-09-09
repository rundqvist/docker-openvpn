#!/bin/sh

if expr "$(var HOST_IP)" : '[0-9][0-9]*\.[0-9][0-9]*\.[0-9][0-9]*\.[0-9][0-9]*$' >/dev/null; then

    network=$(var HOST_IP | sed 's/\([0-9\.]*\)\.[0-9][0-9]*$/\1\.0/g')

    log -d openvpn "HOST_IP is $(var HOST_IP)"

    if [ -z "$(var NETWORK)" ] ; then
        log -v openvpn "Network resolved from HOST_IP is $network"

        var NETWORK "$network"
    fi
else

    log -w openvpn "HOST_IP is unknown."
    var -d HOST_IP

fi

if expr "$(var NETWORK)" : '[0-9][0-9]*\.[0-9][0-9]*\.[0-9][0-9]*\.0$' >/dev/null; then

    log -d openvpn "NETWORK is $(var NETWORK)";

else

    log -w openvpn "NETWORK is unknown.";
    var -d NETWORK

fi