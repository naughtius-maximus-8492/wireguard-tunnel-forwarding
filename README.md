# wireguard-tunnel-forwarding

## Installing Requirements
### Server & Client
- wireguard
### Server Only
- iptables
- iptables-persistent

## Generating Public/Private keys
On both the client and server, run this command in a dedicated area for your keys. For example:
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

Once these are generated the server and peer, add the keys to the files in `wg-configs/` as the tunnel install script copies these in. You will need to edit the `PrivateKey` & `PublicKey` fields in both `wg-server.conf` and `wg-peer.conf` with the keys we generated above. You will also need to add the public IP address of the wireguard server to `Endpoint` in `wg-peer.conf`

### Command Examples
```
# Wireguard Server
root@server-test:~# wg genkey | tee privatekey | wg pubkey > publickey
root@server-test:~# cat privatekey publickey
2BBeRRCv58BejMPUdvzbPaMrdr9ept+Dg4+Z+WAIZmI= # Server Private Key
4XESbxb9z4voktNn4Kmlow3+rYvTDgaqFDrOEQCxfzk= # Server Public Key
root@server-test:~# curl ifconfig.io
192.123.4.56                                 # Server Public IP

# Wireguard Peer
root@peer-test:~# wg genkey | tee privatekey | wg pubkey > publickey
root@peer-test:~# cat privatekey publickey
CLjWcDLrQWF4MWAbcnA1FCxMyyxIfTYgETZX2T0svUs= # Peer Private Key
Fh22Wyq60USJ87cKG37sqwdNe5k0YLSMlDiKDpJdKGU= # Peer Public Key
```

### Config Examples
These config examples use the outputs from the above command samples to fill in the fields. Do not use these keys and IP as you need to generate your own.

```
##################
# wg-server.conf #
##################

[Interface]
Address = 10.0.0.1/24
ListenPort = 51820
PrivateKey = 2BBeRRCv58BejMPUdvzbPaMrdr9ept+Dg4+Z+WAIZmI=

[Peer]
PublicKey = Fh22Wyq60USJ87cKG37sqwdNe5k0YLSMlDiKDpJdKGU=
AllowedIPs = 10.0.0.2/32
PersistentKeepalive = 25

################
# wg-peer.conf #
################

[Interface]
Address = 10.0.0.2/24
PrivateKey = CLjWcDLrQWF4MWAbcnA1FCxMyyxIfTYgETZX2T0svUs=

[Peer]
PublicKey = 4XESbxb9z4voktNn4Kmlow3+rYvTDgaqFDrOEQCxfzk=
Endpoint = 192.123.4.56:51820
AllowedIPs = 0.0.0.0/0
PersistentKeepalive = 25
```
