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

# Enable ipv4 forwarding
echo "Enabling IPV4 forwarding..."

echo "net.ipv4.ip_forward=1" >> /etc/sysctl.conf
sysctl -p

# Generate server and peer keys
echo "Generating server and peer keys..."

SERVER_PRIVATE_KEY=$(wg genkey)
SERVER_PUBLIC_KEY=$(echo $SERVER_PRIVATE_KEY | wg pubkey)

PEER_PRIVATE_KEY=$(wg genkey)
PEER_PUBLIC_KEY=$(echo $PEER_PRIVATE_KEY | wg pubkey)

# Create server config
echo "Generating wireguard server config..."

echo "[Interface]
Address = $SERVER_WG_SUBNET/24
ListenPort = 51820
PrivateKey = $SERVER_PRIVATE_KEY
PostUp=iptables -A FORWARD -i $SERVER_WG_INTERFACE -j ACCEPT; iptables -t nat -A POSTROUTING -o $PHYSICAL_INTERFACE -j MASQUERADE;
PostDown=iptables -D FORWARD -i $SERVER_WG_INTERFACE -j ACCEPT; iptables -t nat -D POSTROUTING -o $PHYSICAL_INTERFACE -j MASQUERADE;

[Peer]
PublicKey = $PEER_PUBLIC_KEY
AllowedIPs = $PEER_WG_SUBNET/32
PersistentKeepalive = 25" > /etc/wireguard/$SERVER_WG_INTERFACE.conf

echo "Wireguard server config built!
"

function echo_client_config {
	# Build command to paste onto client
	echo "###############################################
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
#                     END                     #
###############################################"
}

echo_client_config
echo_client_config > current-client-config.txt
