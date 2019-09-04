#!/bin/bash

set -x
set -e

if [ ! -f /config/server.conf ]; then
    # initialization

    if [ ! -d "/config" ]; then
        mkdir /config
    fi

    cd /config

    export EASYRSA='/etc/easy-rsa'
    export EASYRSA_PKI='/config/pki'
    if [ ! -d "pki" ]; then
        echo "generating pki"
        easyrsa init-pki
        easyrsa --batch build-ca nopass
        easyrsa gen-dh
        EASYRSA_CERT_EXPIRE=3650 easyrsa build-server-full server nopass
        EASYRSA_CRL_DAYS=3650 easyrsa gen-crl
        openvpn --genkey --secret tc.key
    fi
    echo "generating server config"
    if [ "$SCRAMBLE" == 1 ]; then
        SCRAMBLE_LINE="scramble xormask $(shuf -e -n1 {0..9} {a..z} {A..Z})"
    fi
    set +x
    echo "port 1194
proto tcp
sndbuf 0
rcvbuf 0
dev tun
ca pki/ca.crt
cert pki/issued/server.crt
key pki/private/server.key
dh pki/dh.pem
auth sha256
tls-crypt tc.key
topology subnet
duplicate-cn
server 10.232.0.0 255.255.255.0
keepalive 10 60
cipher aes-128-cbc
persist-key
persist-tun
status openvpn-status.log
verb 3
crl-verify pki/crl.pem
$SCRAMBLE_LINE" > server.conf
    set -x

    if [ -z "$PUBLIC_ADDRESS" ]; then
        echo "getting public IP address"
        PUBLIC_ADDRESS="$(curl -s https://api.ipify.org/)"
        echo "found public IP address $PUBLIC_ADDRESS"
    fi

    mkdir clients
    for i in $(seq "${NUM_CLIENT_CONFIGS:-25}"); do
        echo "generating client $i config"
        EASYRSA_CERT_EXPIRE=3650 easyrsa build-client-full "client${i}" nopass
        set +x
	echo "client
dev tun
proto tcp
redirect-gateway def1 bypass-dhcp
dhcp-option DNS 128.52.130.209
dhcp-option DNS 169.239.202.202
sndbuf 0
rcvbuf 0
remote $PUBLIC_ADDRESS ${PUBLIC_PORT:-1194}
resolv-retry infinite
nobind
persist-key
persist-tun
remote-cert-tls server
auth sha256
cipher aes-128-cbc
setenv opt block-outside-dns
verb 3
<ca>
$(cat pki/ca.crt)
</ca>
<cert>
$(cat "pki/issued/client${i}.crt")
</cert>
<key>
$(cat "pki/private/client${i}.key")
</key>
<tls-crypt>
$(cat tc.key)
</tls-crypt>
$SCRAMBLE_LINE" > "clients/client${i}.ovpn"
        set -x
    done
else
    cd /config
fi

mkdir /dev/net
mknod /dev/net/tun c 10 200

iptables -t nat -A POSTROUTING -s 10.232.0.0/24 -j MASQUERADE

openvpn --config /config/server.conf
