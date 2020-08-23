# OpenVPN container for IPVanish
A small OpenVPN client based on Alpine Linux.  
https://hub.docker.com/r/rundqvist/openvpn/

# Appreciate my work?
Do you find this container useful? Please consider a donation.

[![Donate](https://img.shields.io/badge/Donate-Flattr-brightgreen)](https://flattr.com/@rundqvist)
[![Donate](https://img.shields.io/badge/Donate-Buy%20me%20a%20coffee-orange)](https://www.buymeacoffee.com/rundqvist)
[![Donate](https://img.shields.io/badge/Donate-PayPal-blue)](https://www.paypal.com/cgi-bin/webscr?cmd=_s-xclick&hosted_button_id=SZ7J9JL9P5DGE&source=url)

## Features
* Connect to random server
* Reconnects if connection breaks

## Requirements
* A VPN account (currently IPVanish and WeVPN is supported)

[![Sign up](https://img.shields.io/badge/Affiliate-IPVanish_VPN-6fbc44)](https://www.ipvanish.com/?a_bid=48f95966&a_aid=5f3eb2f0be07f)

## Components
* Alpine Linux
* OpenVPN

## Run
```
docker run \
  -d \
  --cap-add=NET_ADMIN \
  --device=/dev/net/tun \
  --name=openvpn \
  --dns [your desired public dns, for example 1.1.1.1] \ 
  -e 'VPN_PROVIDER=[your vpn provider]' \
  -e 'VPN_USERNAME=[your vpn username]' \
  -e 'VPN_PASSWORD=[your vpn password]' \
  -e 'VPN_COUNTRY=[your desired country]' \
  -v /path/to/cache/folder:/cache/ \
  rundqvist/openvpn
```

### Configuration
| Variable | Usage |
|----------|-------|
| _VPN_PROVIDER_ | Your VPN provider ("ipvanish" or "wevpn"). |
| _VPN_USERNAME_ | Your VPN username. |
| _VPN_PASSWORD_ | Your VPN password. |
| _VPN_COUNTRY_ | Desired country (as defined by your VPN provider). |
| VPN_INCLUDED_REMOTES | Host names separated by one space. Restricts VPN to entered remotes. |
| VPN_EXCLUDED_REMOTES | Host names separated by one space. VPN will not connect to entered remotes. |
| VPN_RANDOM_REMOTE | Connects to random remote. "true" or "false". |
_Cursive_ variables are mandatory.

#### IPVanish
Just enter mandatory variables and run. Container will solve configuration.

#### WeVPN
Login to the WeVPN website and use the _Manual Configuration Generator_ to download config. Select Protocol UDP and OpenVPN version v2.4+ when creating configuration.

Put configuration files in the wevpn-folder in the structure below.
```
[your cache folder]
|
└ openvpn
  |
  └ wevpn
```

## Issues
Please report issues at https://github.com/rundqvist/openvpn/issues