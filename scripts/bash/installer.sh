#!/bin/bash

cd `dirname ${BASH_SOURCE[0]}`

function get_free_udp_port
{
    local port=$(shuf -i 2000-65000 -n 1)
    ss -lau | grep $port > /dev/null
    if [[ $? == 1 ]] ; then
        echo "$port"
    else
        get_free_udp_port
    fi
}

if [ "$SERVER_PORT" == "" ]; then
    SERVER_PORT=$( get_free_udp_port )
 fi

if [[ "$EUID" -ne 0 ]]; then
    echo "Sorry, you need to run this as root"
    exit
fi

if [[ ! -e /dev/net/tun ]]; then
    echo "The TUN device is not available. You need to enable TUN before running this script"
    exit
fi

if [ "$( systemd-detect-virt )" == "openvz" ]; then
    echo "OpenVZ virtualization is not supported"
    exit
fi

if [ "$CLIENT_NAME" == "" ]; then
     read -p "Private IP: " -e -i "10.9.0.0/22" PRIVATE_SUBNET
fi

apt-get install software-properties-common -y
add-apt-repository ppa:wireguard/wireguard -y
apt update
apt install linux-headers-$(uname -r) wireguard qrencode -y
echo "net.ipv4.ip_forward=1" >> /etc/sysctl.conf
echo "net.ipv4.conf.all.forwarding=1" >> /etc/sysctl.conf
echo "net.ipv6.conf.all.forwarding=1" >> /etc/sysctl.conf
sysctl -p
SERVER_PRIVKEY=$( wg genkey )
SERVER_PUBKEY=$( echo $SERVER_PRIVKEY | wg pubkey )
SERVER_HOST=$(ip addr | grep 'inet' | grep -v inet6 | grep -vE '127\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}' | grep -oE '[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}' | head -1)
echo "_INTERFACE=wg0
_VPN_NET=$PRIVATE_SUBNET
_SERVER_PORT=$SERVER_PORT
_SERVER_LISTEN=$SERVER_HOST:$SERVER_PORT
_SERVER_PUBLIC_KEY=$SERVER_PUBKEY
_SERVER_PRIVATE_KEY=$SERVER_PRIVKEY" > ../data/wg.def
