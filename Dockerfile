FROM rundqvist/supervisor:latest

LABEL maintainer="mattias.rundqvist@icloud.com"

WORKDIR /app

COPY root /

RUN apk add --update --no-cache openvpn \
	&& chmod 755 /app/openvpn/init.sh \
	&& chmod 755 /app/healthcheck.sh \
	&& chmod 755 /app/entrypoint.sh

ENV VPN_PROVIDER='' \
    VPN_USERNAME='' \
	VPN_PASSWORD='' \
	VPN_COUNTRY='' \
	VPN_INCLUDED_REMOTES='' \
	VPN_EXCLUDED_REMOTES=''

EXPOSE 80 443

#HEALTHCHECK --interval=30s --timeout=60s --start-period=15s \  
# CMD /bin/sh /app/healthcheck.sh

ENTRYPOINT [ "/app/entrypoint.sh" ]