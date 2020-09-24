#!/bin/sh

log -v openvpn "Tls verify $1 $2 $3."

if [ $2 -eq 0 ]
then
	country=$(echo "$1" | sed 's/.*\/\(.*\)-allowed.*/\1/g')
	remote=$(echo "$3" | sed 's/.* CN=\([^,]*\).*/\1/g')
	log -d openvpn "Tls handshake with: $remote ($country)."

	grep -q "^`expr match "$3" ".* CN=\([^,]*\)"`$" "$1" && exit 0
	exit 1
fi

exit 0
