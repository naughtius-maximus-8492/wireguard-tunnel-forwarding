source .env

function print_help {
	echo "Valid arguments:"
	echo "-h        ; Show this menu"
	echo "-p <port> ; Set port to open/close"
	echo "-c        ; Close the port rather than open it"
	echo "-t        ; Makes the iptables rule temporary. Reboots will flush it"
	echo "-u        ; Open a UDP port instead of TCP"
	exit
} 	

help=false

# A : Adds rule
# D : Deletes rule
rule=A

port=-1
protocol=tcp

# When true, runs iptables-save at the end to persist on reboot
save=true

while getopts hp:ctu flag
do
    case "${flag}" in
	h) help=true;;
        p) port=${OPTARG};;
	c) rule=D;;
	t) save=false;;
	u) protocol=udp;;
    esac
done

if (( !($port >= 1 && $port <= 65535) )) ; then
	echo "Port not in valid range (1 - 65535)"
	echo "> port = $port"
	echo "Use -h for help"
	exit
fi

if [ $help == true ] ; then
	print_help
fi

# Print commands	
set -o xtrace 

# iptables PREROUTING rule
iptables -t nat -$rule PREROUTING -i $PHYSICAL_INTERFACE -p $protocol --dport $port -j DNAT --to-destination $CLIENT_IP:$port

# Route packets client -> server
iptables -$rule FORWARD -i $WG_INTERFACE -o $PHYSICAL_INTERFACE -p $protocol --sport $port -s $CLIENT_IP -j ACCEPT

# Route packets server -> client
iptables -$rule FORWARD -i $PHYSICAL_INTERFACE -o $WG_INTERFACE -p $protocol --dport $port -d $CLIENT_IP -j ACCEPT

# Stop printing commands	
set +o xtrace

if [ $save == true ] ; then
	iptables-save > /etc/iptables/rules.v4
fi
