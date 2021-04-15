FROM rundqvist/supervisor:latest

LABEL maintainer="mattias.rundqvist@icloud.com"

WORKDIR /app

RUN apk add --update --no-cache openvpn unrar

COPY root /

ENV VPN_PROVIDER='' \
    VPN_USERNAME='' \
	VPN_PASSWORD='' \
	VPN_COUNTRY='' \
	VPN_INCLUDED_REMOTES='' \
	VPN_EXCLUDED_REMOTES='' \
	VPN_REMOTES_FILTER_MODE='' \
	VPN_RANDOM_REMOTE='' \
	VPN_KILLSWITCH='true'
