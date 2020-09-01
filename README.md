# OpenVPN container
A small OpenVPN container based on Alpine Linux. 

[![Docker pulls](https://img.shields.io/docker/pulls/rundqvist/openvpn.svg)](https://hub.docker.com/r/rundqvist/openvpn)

## Do you find this container useful? 
Please support the development by making a small donation.

[![Support](https://img.shields.io/badge/support-Flattr-brightgreen)](https://flattr.com/@rundqvist)
[![Support](https://img.shields.io/badge/support-Buy%20me%20a%20coffee-orange)](https://www.buymeacoffee.com/rundqvist)
[![Support](https://img.shields.io/badge/support-PayPal-blue)](https://www.paypal.com/cgi-bin/webscr?cmd=_s-xclick&hosted_button_id=SZ7J9JL9P5DGE&source=url)

## Features
* Connect to random server
* Reconnects if connection breaks
* Healthcheck (checking that ip differs from public ip)

## Requirements
* A supported VPN account (currently [IPVanish](https://www.ipvanish.com/?a_bid=48f95966&a_aid=5f3eb2f0be07f) or [WeVPN](https://www.wevpn.com/aff/rundqvist))

[![Sign up](https://img.shields.io/badge/sign_up-IPVanish_VPN-6fbc44)](https://www.ipvanish.com/?a_bid=48f95966&a_aid=5f3eb2f0be07f)
[![Sign up](https://img.shields.io/badge/sign_up-WeVPN-e33866)](https://www.wevpn.com/aff/rundqvist)

## Components
* Alpine Linux
* Supervisor container as base (https://hub.docker.com/r/rundqvist/supervisor)
* OpenVPN (https://github.com/OpenVPN/openvpn)

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

## Configuration

### Variables

| Variable | Usage |
|----------|-------|
| _VPN_PROVIDER_ | Your VPN provider ("[ipvanish](https://www.ipvanish.com/?a_bid=48f95966&a_aid=5f3eb2f0be07f)" or "[wevpn](https://www.wevpn.com/aff/rundqvist)"). |
| _VPN_USERNAME_ | Your VPN username. |
| _VPN_PASSWORD_ | Your VPN password. |
| _VPN_COUNTRY_ | ISO 3166-1 alpha-2 country code (https://en.wikipedia.org/wiki/ISO_3166-1_alpha-2). |
| VPN_INCLUDED_REMOTES | Host names separated by one space. Restricts VPN to entered remotes. |
| VPN_EXCLUDED_REMOTES | Host names separated by one space. VPN will not connect to entered remotes. |
| VPN_RANDOM_REMOTE | Connects to random remote. "true" or "false". |

Variables in _cursive_ is mandatory.

### Volumes

| Folder | Usage |
|--------|-------|
| /cache/ | Used for caching original configuration files from vpn provider |

## Setup

### IPVanish
Just enter mandatory variables and run. Container will solve configuration.

### WeVPN
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
Please report issues at https://github.com/rundqvist/docker-openvpn/issues
