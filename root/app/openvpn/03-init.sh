#!/bin/sh

log -v openvpn "Checking network..."

if var -e NETWORK; then

    log -i openvpn "Adding route for communication with network $(var NETWORK)/24";
    route add -net $(var NETWORK) netmask 255.255.255.0 gw $(ip route | awk '/default/ { print $3 }')

else

    log -w openvpn "NETWORK missing or wrong format. May cause communication problems.";

fi