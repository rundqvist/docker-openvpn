#!/bin/sh

while getopts ":e:c:" arg; do
    case $arg in
        e) exec=$OPTARG;;
        c) country=$OPTARG;;
    esac
done

log -v openvpn "Provider ipvanish $exec"

case $exec in

    #
    # Configure
    #
    configure)
    
        var VPN_PORT 443

    ;;

    #
    # Resolve remote hostname
    #
    host)

        remote=$(tac /var/log/openvpn-$country.log | grep '[[a-z0-9\-]\.ipvanish\.com]' -m 1 | sed -n 's/.*\[\([a-z0-9\-]*\.ipvanish\.com\)\].*/\1/p')

        if [ -z "$remote" ]
        then
            log -v openvpn "Could not resolve remote hostname."
            exit 1;
        fi

        echo "$remote"

    ;;

    #
    # Setup
    #
    setup)

        ipvanishCountry="$country"
        if [ "$country" = "GB" ]
        then
            ipvanishCountry="UK";
            log -d openvpn "Parsing config files for 'UK' instead of 'GB' since IPVanish differs from ISO 3166-1 alpha-2."
        fi

        if [ -z "$(find /cache/openvpn/ipvanish/ -name "*-$ipvanishCountry-*")" ]
        then
            log -e openvpn "No config files found country $country. Ignoring. "
            exit 1;
        fi

        #
        # Copy one config file as template
        #
        find /cache/openvpn/ipvanish/ -name "*-$ipvanishCountry-*" -print | head -1 | xargs -I '{}' cp {} /app/openvpn/config-$country.ovpn

        #
        # Remove verify-x509-name and add tls-verify and cert path
        #
        sed -i '/verify-x509-name /d' /app/openvpn/config-$country.ovpn
        echo "tls-verify '/app/openvpn/tls-verify.sh /app/openvpn/$country-allowed.remotes'" >> /app/openvpn/config-$country.ovpn
        sed -i 's/^ca \(.*\)/ca \/app\/openvpn\/\1/g' /app/openvpn/config-$country.ovpn

        #
        # Mute replay warnings
        # 
        echo "mute-replay-warnings" >> /app/openvpn/config-$country.ovpn

        #
        # Resolve remotes
        #
        find /cache/openvpn/ipvanish/ -name "*-$ipvanishCountry-*" -exec sed -n -e 's/^remote \(.*\) \(.*\)/\1/p' {} \; | sort > /app/openvpn/$country-allowed.remotes

    ;;

    #
    # Update
    #
    update)
    
        dateCurrent=$(date +%d)
        dateUpdated=$(cat /cache/openvpn/ipvanish/date_updated 2>/dev/null)

        if [ "$dateCurrent" != "$dateUpdated" ]
        then
            log -i openvpn "Updating ipvanish configuration files."

            mkdir -p /cache/openvpn/ipvanish
            rm -f /cache/openvpn/ipvanish/configs.zip

            wget -q https://www.ipvanish.com/software/configs/configs.zip -P /cache/openvpn/ipvanish/ 2>/dev/null
            
            if [ $? -eq 1 ]
            then
                log -w openvpn "Download failed. "
            else
                log -d openvpn "Unzipping configs."
                unzip -q -o /cache/openvpn/ipvanish/configs.zip -d /cache/openvpn/ipvanish/

                echo $dateCurrent > /cache/openvpn/ipvanish/date_updated
            fi
        else
            log -d openvpn "Config recently updated. Skipping..."
        fi

        if [ ! -f /app/openvpn/ca.ipvanish.com.crt ]
        then
            log -d openvpn "Copying certificate."
            cp -f /cache/openvpn/ipvanish/ca.ipvanish.com.crt /app/openvpn/
        fi

    ;;
esac

exit 0;
