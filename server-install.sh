source .env
apt update
apt install wireguard iptables iptables-persistent

# Allow peer to access internet
iptables -t nat -A POSTROUTING -o $PHYSICAL_INTERFACE -j MASQUERADE

# Save rules for reboot
iptables-save > /etc/iptables/rules.v4
