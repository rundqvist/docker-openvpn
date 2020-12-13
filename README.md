# OpenVPN container
A user friendly OpenVPN container based on Alpine Linux. 

[![Docker pulls](https://img.shields.io/docker/pulls/rundqvist/openvpn.svg)](https://hub.docker.com/r/rundqvist/openvpn)
[![image size](https://img.shields.io/docker/image-size/rundqvist/openvpn.svg)](https://hub.docker.com/r/rundqvist/openvpn)
[![commit activity](https://img.shields.io/github/commit-activity/m/rundqvist/docker-openvpn)](https://github.com/rundqvist/docker-openvpn)
[![last commit](https://img.shields.io/github/last-commit/rundqvist/docker-openvpn.svg)](https://github.com/rundqvist/docker-openvpn)

## Do you find this container useful? 
Please support the development by making a small donation.

[![Support](https://img.shields.io/badge/support-Flattr-brightgreen)](https://flattr.com/@rundqvist)
[![Support](https://img.shields.io/badge/support-Buy%20me%20a%20coffee-orange)](https://www.buymeacoffee.com/rundqvist)
[![Support](https://img.shields.io/badge/support-PayPal-blue)](https://www.paypal.com/cgi-bin/webscr?cmd=_s-xclick&hosted_button_id=SZ7J9JL9P5DGE&source=url)

## Features
* Killswitch (kills network if vpn is down)
* Self healing (restarts vpn if connection breaks down)
* Connect to random server
* Healthcheck (checking that ip differs from public ip)

## Requirements
* A supported VPN account.

[![Sign up](https://img.shields.io/badge/sign_up-IPVanish_VPN-6fbc44)](https://www.ipvanish.com/?a_bid=48f95966&a_aid=5f3eb2f0be07f)
[![Sign up](https://img.shields.io/badge/sign_up-Ivacy_VPN-3dacf3)](https://www.ivacy.com/get-30-days-free-vpn/?refer=802326)
[![Sign up](https://img.shields.io/badge/sign_up-WeVPN-e33866)](https://www.wevpn.com/aff/rundqvist)

## Components
Built on [rundqvist/supervisor](https://hub.docker.com/r/rundqvist/supervisor) container.
* [Alpine Linux](https://www.alpinelinux.org)
* [Supervisor](https://github.com/Supervisor/supervisor)
* [OpenVPN](https://github.com/OpenVPN/openvpn)

## Run
```
docker run \
  -d \
  --cap-add=NET_ADMIN \
  --device=/dev/net/tun \
  --name=openvpn \
  --dns 1.1.1.1 \ 
  --dns 1.0.0.1 \ 
  -e 'HOST_IP=[your server ip]' \
  -e 'VPN_PROVIDER=[your vpn provider]' \
  -e 'VPN_USERNAME=[your vpn username]' \
  -e 'VPN_PASSWORD=[your vpn password]' \
  -e 'VPN_COUNTRY=[your desired country]' \
  -v /path/to/cache/folder:/cache/ \
  rundqvist/openvpn
```

### Configuration

#### Variables

| Variable | Usage |
|----------|-------|
| HOST_IP | IP of server on your local network (needed for communication between container and local network).  |
| _VPN_PROVIDER_ | Supported providers:<br />- [ipvanish](https://www.ipvanish.com/?a_bid=48f95966&a_aid=5f3eb2f0be07f)<br />- [ivacy](https://www.ivacy.com/get-30-days-free-vpn/?refer=802326)<br />- [wevpn](https://www.wevpn.com/aff/rundqvist) |
| _VPN_USERNAME_ | Your VPN username. |
| _VPN_PASSWORD_ | Your VPN password. |
| _VPN_COUNTRY_ | ISO 3166-1 alpha-2 country code (https://en.wikipedia.org/wiki/ISO_3166-1_alpha-2). |
| VPN_KILLSWITCH | Kills network if vpn is down. <br />`true` (default) or `false`. |
| VPN_INCLUDED_REMOTES | Host names separated by one space. VPN will _only_ connect to entered remotes. |
| VPN_EXCLUDED_REMOTES | Host names separated by one space. VPN will _not_ connect to entered remotes. |
| VPN_REMOTES_FILTER_MODE | If set, included/excluded-filtering of remotes resulting in an empty list will cause vpn to not connect. <br />`strict`, `strict-included` or `strict-excluded`. |
| VPN_RANDOM_REMOTE | Connects to random remote. <br />`true` or `false` (default). |

Variables in _cursive_ is mandatory.

#### Volumes

| Folder | Usage |
|--------|-------|
| /cache/ | Used for caching original configuration files from vpn provider. |

## Setup

### IPVanish/Ivacy
Just enter mandatory variables and run. Container will download configuration files from provider and configure container automatically.

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

## Use
Add `--net container:openvpn` (the name if this container) on other container to route all traffic via vpn.

Remember to configure `HOST_IP` if you want to reach services inside the container from your local network.

Also, the ports you want to reach in the other container must be configured in this container.

## Issues
Please report issues at https://github.com/rundqvist/docker-openvpn/issues
