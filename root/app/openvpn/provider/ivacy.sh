#!/bin/sh

while getopts ":e:c:" arg; do
    case $arg in
        e) exec=$OPTARG;;
        c) country=$OPTARG;;
    esac
done

log -v "Provider ivacy $exec"

case $exec in

    #
    # Configure
    #
    configure)
    
        var VPN_PORT 53

    ;;

    #
    # Resolve remote hostname
    #
    host)

        ip=$(tac /var/log/openvpn-$country.log | grep -m 1 'Peer Connection Initiated' | grep -oE '([0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3})')

        log -v "Vpn ($country) connected to ip: $ip"

        while read -r remote
        do
            remoteIp=$(ping -q -c 1 $remote | head -n 1 | grep -oE '([0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3})')

            log -v "Host $remote has ip $remoteIp"

            if [ "$ip" == "$remoteIp" ]
            then
                break
            fi
        done < /app/openvpn/$country-allowed.remotes

        if [ -z "$remote" ]
        then
            log -w "Failed to resolve remote hostname."
            exit 1;
        fi

        echo "$remote"

    ;;

    #
    # Setup
    #
    setup)

        countryName="$(var -k country $country)"
        log -d "Translating $country to $countryName"

        if [ -z "$(find /cache/openvpn/ivacy/ -name "$countryName*UDP.ovpn")" ] ; then
            log -e "No config files found country $country. Ignoring. "
            exit 1;
        fi

        #
        # Copy one config file as template
        #
        find /cache/openvpn/ivacy/ -name "$countryName*UDP.ovpn" -print | head -1 | xargs -I '{}' cp {} /app/openvpn/config-$country.ovpn

        #
        # Resolve remotes
        #
        find /cache/openvpn/ivacy/ -name "$countryName*UDP.ovpn" -exec sed -n -e 's/^remote \(.*\) \(.*\)/\1/p' {} \; | sort > /app/openvpn/$country-allowed.remotes

    ;;

    #
    # Update
    #
    update)
    
        dateCurrent=$(date +%d)
        dateUpdated=$(cat /cache/openvpn/ivacy/date_updated 2>/dev/null)

        if [ "$dateCurrent" != "$dateUpdated" ]
        then
            log -i "Updating ivacy configuration files."

            mkdir -p /cache/openvpn/ivacy
            rm -f /cache/openvpn/ivacy/OpenVPN-Configs-with-certificate.rar

            wget -q https://ivacy.s3.amazonaws.com/support/OpenVPN-Configs-with-certificate.rar -P /cache/openvpn/ivacy/ 2>/dev/null
            
            if [ $? -eq 1 ]
            then
                log -w "Download failed. "
            else
                log -d "Extract configs."
                unrar -o+ e /cache/openvpn/ivacy/OpenVPN-Configs-with-certificate.rar /cache/openvpn/ivacy/ >/dev/null

                echo $dateCurrent > /cache/openvpn/ivacy/date_updated
            fi
        else
            log -d "Config recently updated. Skipping..."
        fi

        # if [ ! -f /app/openvpn/ca.ipvanish.com.crt ]
        # then
        #     log -d "Copying certificate."
        #     cp -f /cache/openvpn/ipvanish/ca.ipvanish.com.crt /app/openvpn/
        # fi

    ;;
esac

exit 0;
