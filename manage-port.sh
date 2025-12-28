#!/bin/bash

source .env
source functions.sh

validate_env

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
	echo "ERROR: Invalid argument for -p [1 - 65535]. Use -h for help."
	exit
fi

if  [[ $protocol != "udp" && $protocol != "tcp" ]] ; then 
	echo "ERROR: Invalid argument for -t [ tcp | udp ]. Use -h for help."
	exit
fi

if [[ $rule == "close" ]] ; then
	echo "ACTION: $rule $protocol $port"
	rule="D"
elif [[ $rule == "open" ]] ; then
	echo "ACTION: $rule $protocol $port"
	rule="A"
else
	echo "ERROR: Invalid arg for -s [ open | close ]. Use -h for help."
	exit
fi

# Print commands	
set -o xtrace 

# Route inbound connections to wireguard interface
iptables -$rule FORWARD -i $PHYSICAL_INTERFACE -o $SERVER_WG_INTERFACE -p $protocol --dport $port -m conntrack --ctstate NEW -j ACCEPT

# Set dnat for inbound connections
iptables -t nat -$rule PREROUTING -i $PHYSICAL_INTERFACE -p $protocol --dport $port -m conntrack --ctstate NEW -j DNAT --to-destination $WG_PEER_ADDRESS


# Stop printing commands	
set +o xtrace

iptables-save > /etc/iptables/rules.v4

