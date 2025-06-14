# wireguard-tunnel-forwarding
**Do not run these scripts without following the configuration steps below or it will not work**
## Requirements
### Server & Peer Hosts
- wireguard
### Server Host Only
- iptables
- iptables-persistent
- Port 51820 opened on your firewalls (both external and internal)

If you're using apt, you can simply install using these commands:
```
apt install wireguard # Wireguard Peer

apt install wireguard iptables iptables-persistent # Wireguard Server
```

**It is also recommended to run these commands as root on the peer and server as this touches many places where root can only access**

## Setting up peer and server configs
### Wireguard Key Pairs
On both the peer and server, run this command in a dedicated area for your keys. For example:
```
# Use your user home dir
cd ~

# Create dedicate dir in your home for keys
mkdir wg-keys
cd wg-keys

# Generate and display key pair 
wg genkey | tee privatekey | wg pubkey > publickey
cat privatekey publickey
```

Once these are generated the server and peer, add the keys to the files in `wg-configs/` as the tunnel install script copies these in. You will need to edit the `PrivateKey` & `PublicKey` fields in both `wg-server.conf` and `wg-peer.conf` with the keys we generated above. 

### Endpoint/Public IP
In your peer config, you need to supply the public IP of the wireguard server host. This can be obtained using `curl ifconfig.io` or in your panel if you're using a managed VPS hosting service.

### Command Examples
```
# Wireguard Server
root@wireguard-server-host:~# wg genkey | tee privatekey | wg pubkey > publickey
root@wireguard-server-host:~# cat privatekey publickey
2BBeRRCv58BejMPUdvzbPaMrdr9ept+Dg4+Z+WAIZmI= # Server Private Key
4XESbxb9z4voktNn4Kmlow3+rYvTDgaqFDrOEQCxfzk= # Server Public Key
root@wireguard-server-host:~# curl ifconfig.io
192.123.4.56                                 # Server Public IP

# Wireguard Peer
root@wireguard-peer-host:~# wg genkey | tee privatekey | wg pubkey > publickey
root@wireguard-peer-host:~# cat privatekey publickey
CLjWcDLrQWF4MWAbcnA1FCxMyyxIfTYgETZX2T0svUs= # Peer Private Key
Fh22Wyq60USJ87cKG37sqwdNe5k0YLSMlDiKDpJdKGU= # Peer Public Key
```

### Config Examples
These config examples use the outputs from the above command samples to fill in the fields. Do not use these keys and IP as you need to generate your own.

```
#####################################################
# <WIREGUARD_SERVER_HOST>/wg-configs/wg-server.conf #
#####################################################

[Interface]
Address = 10.0.0.1/24
ListenPort = 51820
PrivateKey = 2BBeRRCv58BejMPUdvzbPaMrdr9ept+Dg4+Z+WAIZmI=

[Peer]
PublicKey = Fh22Wyq60USJ87cKG37sqwdNe5k0YLSMlDiKDpJdKGU=
AllowedIPs = 10.0.0.2/32
PersistentKeepalive = 25

#################################################
# <WIREGUARD_PEER_HOST>/wg-configs/wg-peer.conf #
#################################################

[Interface]
Address = 10.0.0.2/24
PrivateKey = CLjWcDLrQWF4MWAbcnA1FCxMyyxIfTYgETZX2T0svUs=

[Peer]
PublicKey = 4XESbxb9z4voktNn4Kmlow3+rYvTDgaqFDrOEQCxfzk=
Endpoint = 192.123.4.56:51820
AllowedIPs = 0.0.0.0/0
PersistentKeepalive = 25
```

## Physical Interface
> NOTE: This only needs to be done on the wireguard server host as it only affects iptables commands.

The `.env` file has the `PHYSICAL_INTERFACE` set to `eth0` by default. This may not be the same on all servers. You can find this out by running the command `ip addr` which will give an output that looks like this:

```
root@wireguard-server-host:~# ip addr
1: lo: <LOOPBACK,UP,LOWER_UP> mtu 65536 qdisc noqueue state UNKNOWN group default qlen 1000
    link/loopback 00:00:00:00:00:00 brd 00:00:00:00:00:00
    inet 127.0.0.1/8 scope host lo
       valid_lft forever preferred_lft forever
    inet6 ::1/128 scope host noprefixroute
       valid_lft forever preferred_lft forever
2: ens18: <BROADCAST,MULTICAST,UP,LOWER_UP> mtu 1500 qdisc fq_codel state UP group default qlen 1000
    link/ether bc:24:11:1e:b3:07 brd ff:ff:ff:ff:ff:ff
    altname enp0s18
    inet 192.168.1.2/24 brd 192.168.1.255 scope global dynamic ens18
       valid_lft 84404sec preferred_lft 84404sec
    inet6 fe80::be24:11ff:fe1e:b307/64 scope link
       valid_lft forever preferred_lft forever
```

We can see here that my physical interface is actually `ens18` so you should change `eth0` to `ens18`.

# Running the Scripts
Once these are all set, run `./tunnel-install.sh -s` on the server and `./tunnel-install.sh -p` on the peer server. 

To open ports, run `./manage-port.sh -h` on the **wireguard server host** to see your options. As an example, this is what opening TCP port 42420 looks like:

```
root@wireguard-server-host:~/wireguard-tunnel-forwarding-master# ./manage-port.sh -p 42420
++ iptables -t nat -A PREROUTING -i ens18 -p tcp --dport 42420 -j DNAT --to-destination 10.0.0.2:42420
++ iptables -A FORWARD -i wg0 -o ens18 -p tcp --sport 42420 -s 10.0.0.2 -j ACCEPT
++ iptables -A FORWARD -i ens18 -o wg0 -p tcp --dport 42420 -d 10.0.0.2 -j ACCEPT
++ set +o xtrace
```
