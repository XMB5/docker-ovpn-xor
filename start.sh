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
    SCRAMBLE_LINE="scramble xormask $(hexdump -n 8 -e '4/4 "%08x" 1 "\n"' /dev/urandom)"
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
server 10.81.0.0 255.255.255.0
push \"redirect-gateway def1 bypass-dhcp\"
push \"dhcp-option DNS 128.52.130.209\"
keepalive 10 60
cipher aes-128-cbc
persist-key
persist-tun
status openvpn-status.log
verb 3
crl-verify pki/crl.pem
$SCRAMBLE_LINE" > server.conf

    if [ -z "$PUBLIC_ADDRESS" ]; then
        echo "getting public IP address"
        PUBLIC_ADDRESS="$(curl -s https://api.ipify.org/)"
        echo "found public IP address $PUBLIC_ADDRESS"
    fi

    for i in `seq 1`; do
        echo "generating client $i config"
        EASYRSA_CERT_EXPIRE=3650 easyrsa build-client-full client${i} nopass
        echo "client
dev tun
proto tcp
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
$(cat pki/issued/client${i}.crt)
</cert>
<key>
$(cat pki/private/client${i}.key)
</key>
<tls-crypt>
$(cat tc.key)
</tls-crypt>
$SCRAMBLE_LINE" > client${i}.ovpn
    done
fi

mkdir /dev/net
mknod /dev/net/tun c 10 200

openvpn --config /config/server.conf