source .env
apt install wireguard iptables iptables-persistent
iptables -t nat -A POSTROUTING -o $PHYSICAL_INTERFACE -j MASQUERADE
iptables-save > /etc/iptables/rules.v4
