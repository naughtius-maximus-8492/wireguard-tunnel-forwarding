source .env

function server_setup {
	# Allow peer to access internet
	iptables -t nat -A POSTROUTING -o $PHYSICAL_INTERFACE -j MASQUERADE

	# Save rules for reboot
	iptables-save > /etc/iptables/rules.v4

	# Enable ipv4 forwarding
	echo 1 > /proc/sys/net/ipv4/ip_forward
	sysctl -p

	# Use server configs
	cp wg-configs/wg-server.conf /etc/wireguard/wg0.conf

	# Enable service to start now and at boot
	systemctl enable --now wg-quick@wg0

	exit
}

function peer_setup {
	# Use client configs
	cp wg-configs/wg-peer.conf /etc/wireguard/wg0.conf

	# Enable service to start now and at boot
	systemctl enable --now wg-quick@wg0

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
