[Interface]
Address = $_VPN_IP
PrivateKey = $_PRIVATE_KEY
DNS = 9.9.9.9, 8.8.8.8

[Peer]
PublicKey = $_SERVER_PUBLIC_KEY
AllowedIPs = 0.0.0.0/0, ::/0
Endpoint = $_SERVER_LISTEN
PersistentKeepalive = 25

