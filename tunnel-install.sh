source .env

function server_setup {
	echo "Installing wireguard with the server config..."

	# Allow peer to access internet
	iptables -t nat -A POSTROUTING -o $PHYSICAL_INTERFACE -j MASQUERADE

	# Save rules for reboot
	iptables-save > /etc/iptables/rules.v4

	# Enable ipv4 forwarding
	echo 1 > /proc/sys/net/ipv4/ip_forward
	sysctl -p

	# Create server config
	echo "[Interface]
	Address = 10.0.0.1/24
	ListenPort = 51820
	PrivateKey = $SERVER_PRIVATE_KEY

	[Peer]
	PublicKey = $PEER_PUBLIC_KEY
	AllowedIPs = 10.0.0.2/32
	PersistentKeepalive = 25" > output.txt
	
	# Enable service to start now and at boot
	systemctl enable --now wg-quick@wg0
	systemctl status wg-quick@wg0

	exit
}

function peer_setup {
	echo "Installing wireguard with the peer config..."

	# Use client configs
	cp wg-configs/wg-peer.conf /etc/wireguard/wg0.conf

	# Enable service to start now and at boot
	systemctl enable --now wg-quick@wg0
	systemctl status wg-quick@wg0

	exit
}	


while getopts hsp flag
do
	case "${flag}" in
		s) server_setup ;;
		p) peer_setup ;;
	esac
done

echo "Valid arguments:"
echo "-s	; Install server files"
echo "-p	; Install peer files"
exit
