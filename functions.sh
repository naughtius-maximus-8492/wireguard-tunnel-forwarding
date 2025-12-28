#!/bin/bash

validate_env() 
{
	if [[ -z $PHYSICAL_INTERFACE ]] ; then
		echo "Assign PHYSICAL_INTERFACE a value in .env before continuing."
		exit
	fi

	if [[ -z $SERVER_PUBLIC_IP ]] ; then
		echo "Assign SERVER_PUBLIC_IP a value in .env before continuing."
		exit
	fi
}

print_help() 
{
	echo "Help Menu:"
	echo "-h            ; Show this menu"
	echo ""
	echo "-- Port management --"
	echo "-p <port>     ; Port to manage"
	echo "-t <protocol> ; Set to use [ tcp | udp]"
	echo "-s <state>    ; Set to [ open | close ] port"
	echo ""
	echo "-- iptables management --"
	echo "-l            ; List open ports"
	exit
} 	

show_ports()
{
	echo "Open ports:"
	iptables -S | grep dport | awk '{print $10,$12}'
	exit
}

echo_client_config() 
{
	# Build command to paste onto client
	echo "###############################################
# PASTE THE COMMAND BELOW INTO YOUR PEER HOST #
###############################################

echo \"[Interface]
Address = $WG_PEER_ADDRESS/24
PrivateKey = $PEER_PRIVATE_KEY
MTU=$MTU

[Peer]
PublicKey = $SERVER_PUBLIC_KEY
Endpoint = $SERVER_PUBLIC_IP:$WG_PORT
AllowedIPs = 0.0.0.0/0
PersistentKeepalive = 25\" > /etc/wireguard/$PEER_WG_INTERFACE.conf

###############################################
#                     END                     #
###############################################"
}

