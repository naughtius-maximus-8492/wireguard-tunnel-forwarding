source .env

function print_help {
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

function show_ports {
	echo "Open ports:"
	iptables -S | grep dport | awk '{print $10,$12}'
	exit
}

# Default to showing help when no args present
if [ "$#" -lt 1 ]; then
	print_help
fi

# A : Adds rule
# D : Deletes rule
rule=

port=-1
protocol=

while getopts hlp:t:s: flag
do
    case "${flag}" in
	h) print_help;;
	l) show_ports;;
	p) port=${OPTARG};;
	t) protocol=${OPTARG,,};;
	s) rule=${OPTARG,,};;
	*) exit;;
    esac
done

## Validate args 

# Exit if port not in usable range
if (( !($port >= 1 && $port <= 65535) )) ; then
	echo "Port not in valid range (1 - 65535). Use -h for help."
	exit
fi

if  [[ $protocol != "udp" && $protocol != "tcp" ]] ; then 
	echo "ERROR: Protocol must be set to a valid value [ tcp | udp ]. Use -h for help."
	exit
fi

if [[ $rule == "close" ]] ; then
	echo "ACTION: $rule $protocol $port"
	rule="D"
elif [[ $rule == "open" ]] ; then
	echo "ACTION: $rule $protocol $port"
	rule="A"
else
	echo "ERROR: You haven't specified whether to open or close port $port. Use -h for help."
	exit
fi

# Print commands	
set -o xtrace 

# Route packets client -> server
iptables -$rule FORWARD -i $PHYSICAL_INTERFACE -o $SERVER_WG_INTERFACE -p $protocol --dport $port -m conntrack --ctstate NEW -j ACCEPT

# Route packets server -> client
iptables -t nat -$rule PREROUTING -i $PHYSICAL_INTERFACE -p $protocol --dport $port -m conntrack --ctstate NEW -j DNAT --to-destination $PEER_WG_SUBNET


# Stop printing commands	
set +o xtrace

iptables-save > /etc/iptables/rules.v4

