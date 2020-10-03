#!/bin/sh

while getopts ":e:c:" arg; do
    case $arg in
        e) exec=$OPTARG;;
        c) country=$OPTARG;;
    esac
done

log -v openvpn "Provider wevpn $exec"

case $exec in

    #
    # Configure
    #
    configure)
    
        var VPN_PORT 1194

    ;;

    #
    # Resolve remote hostname
    #
    host)

        ip=$(tac /var/log/openvpn-$country.log | grep -m 1 'Peer Connection Initiated' | grep -oE '([0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3})')

        log -v openvpn "Vpn ($country) connected to ip: $ip"

        while read -r remote
        do
            remoteIp=$(ping -q -c 1 $remote | head -n 1 | grep -oE '([0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3})')

            log -v openvpn "Host $remote has ip $remoteIp"

            if [ "$ip" == "$remoteIp" ]
            then
                break
            fi
        done < /app/openvpn/$country-allowed.remotes

        if [ -z "$remote" ]
        then
            log -w openvpn "Failed to resolve remote hostname."
            exit 1;
        fi

        echo "$remote"

    ;;

    #
    # Setup
    #
    setup)

        if [ -z "$(find /cache/openvpn/wevpn/ -name "$country\_*")" ] ; then
            log -e openvpn "No config files found country $country. Ignoring. "
            exit 1;
        fi

        #
        # Copy one config file as template
        #
        find /cache/openvpn/wevpn/ -name "$country\_*" -print | head -1 | xargs -I '{}' cp {} /app/openvpn/config-$country.ovpn

        #
        # Resolve remotes
        #
        find /cache/openvpn/wevpn/ -name "$country\_*" -exec sed -n -e 's/^remote \(.*\) \(.*\)/\1/p' {} \; | sort > /app/openvpn/$country-allowed.remotes

    ;;

    #
    # Update
    #
    update)
    
        log -w openvpn "Provider does not support auto update."

    ;;
esac

exit 0;
