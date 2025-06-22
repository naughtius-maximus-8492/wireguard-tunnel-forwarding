source .env

# Validate .env
if [[ -z $PHYSICAL_INTERFACE ]] ; then
	echo "Assign PHYSICAL_INTERFACE a value in .env before continuing."
	exit
fi

if [[ -z $SERVER_PUBLIC_IP ]] ; then
	echo "Assign SERVER_PUBLIC_IP a value in .env before continuing."
	exit
fi

echo "Setting iptables rules to enable internet access..."

# Allow peer to access internet
iptables -t nat -A POSTROUTING -o $PHYSICAL_INTERFACE -j MASQUERADE

# Save rules for reboot persistence
iptables-save > /etc/iptables/rules.v4

# Enable ipv4 forwarding
echo 1 > /proc/sys/net/ipv4/ip_forward
sysctl -p

# Generate server and peer keys
echo "Generating server and peer keys..."

SERVER_PRIVATE_KEY=$(wg genkey)
SERVER_PUBLIC_KEY=$(echo $SERVER_PRIVATE_KEY | wg pubkey)

PEER_PRIVATE_KEY=$(wg genkey)
PEER_PUBLIC_KEY=$(echo $PEER_PRIVATE_KEY | wg pubkey)

# Create server config
echo "Setting up wireguard config..."

echo "[Interface]
Address = $SERVER_WG_SUBNET/24
ListenPort = 51820
PrivateKey = $SERVER_PRIVATE_KEY

[Peer]
PublicKey = $PEER_PUBLIC_KEY
AllowedIPs = $PEER_WG_SUBNET/32
PersistentKeepalive = 25" > /etc/wireguard/$SERVER_WG_INTERFACE.conf


# Build command to paste onto client
echo "Wireguard server config built!

###############################################
# PASTE THE COMMAND BELOW INTO YOUR PEER HOST #
###############################################

echo \"[Interface]
Address = $PEER_WG_SUBNET/24
PrivateKey = $PEER_PRIVATE_KEY

[Peer]
PublicKey = $SERVER_PUBLIC_KEY
Endpoint = $SERVER_PUBLIC_IP:$WG_PORT
AllowedIPs = 0.0.0.0/0
PersistentKeepalive = 25\" > /etc/wireguard/$PEER_WG_INTERFACE.conf

###############################################
#                  END PASTE                  #
###############################################"
