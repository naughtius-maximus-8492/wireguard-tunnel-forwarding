source .env

function print_help {
	echo "Help Menu:"
	echo "-h        ; Show this menu"
	echo ""
	echo "-- Port management --"
	echo "-p <port> ; Set port to open/close"
	echo "-c        ; Close the port rather than open it"
	echo "-u        ; Open a UDP port instead of TCP"
	echo ""
	echo "-- iptables management --"
	echo "-t        ; Makes the iptables rule temporary. Reboots will flush it"
	echo "-s        ; Show open ports"
	exit
} 	

function show_ports {
	echo "Open ports:"
	iptables -S | grep dport | awk '{print $12,$14}'
	exit
}

# Default to showing help when no args present
if [ "$#" -lt 1 ]; then
	print_help
fi

# A : Adds rule
# D : Deletes rule
rule=A

port=-1
protocol=tcp

# When true, runs iptables-save at the end to persist on reboot
save=true

while getopts hsp:ctu flag
do
    case "${flag}" in
	h) print_help;;
	s) show_ports;;
        p) port=${OPTARG};;
	c) rule=D;;
	t) save=false;;
	u) protocol=udp;;
	*) exit;;
    esac
done

# Exit if port not in usable range
if (( !($port >= 1 && $port <= 65535) )) ; then
	echo "Port not in valid range (1 - 65535)"
	echo "> port = $port"
	echo "Use -h for help"
	exit
fi

# Print commands	
set -o xtrace 

# iptables PREROUTING rule
iptables -t nat -$rule PREROUTING -i $PHYSICAL_INTERFACE -p $protocol --dport $port -j DNAT --to-destination $PEER_WG_SUBNET:$port

# Route packets client -> server
iptables -$rule FORWARD -i $SERVER_WG_INTERFACE -o $PHYSICAL_INTERFACE -p $protocol --sport $port -s $PEER_WG_SUBNET -j ACCEPT

# Route packets server -> client
iptables -$rule FORWARD -i $PHYSICAL_INTERFACE -o $SERVER_WG_INTERFACE -p $protocol --dport $port -d $PEER_WG_SUBNET -j ACCEPT

# Stop printing commands	
set +o xtrace

if [ $save == true ] ; then
	iptables-save > /etc/iptables/rules.v4
fi
