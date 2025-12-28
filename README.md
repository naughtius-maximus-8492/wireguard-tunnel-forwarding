# wireguard-tunnel-forwarding
These scripts allow you to quickly set up a full Wireguard tunnel between a peer and server host and open ports between the two. This allows you to run your services on the peer host and then expose it via the server hosts network. You may want to do this for a few reasons:
- Your ISP puts you behind CGNAT making you unable to port forward.
- You don't want to expose your services from your home's public IP but are happy to do it through a server on different IP (e.g. cheap VPS).
- You want to use another server's DDOS protection without running your services on that specific machine.

These scripts simplify the setup and management of this.

## General Terminlogy
### Peer Host
This is the machine you want to host your servers on. For example, a game server would run on the peer host but have its network exposed on the server host.
### Server Host
This is the machine you're hosting your wireguard server on and has access to the network used to expose your services. A publically accessible VPS in a datacenter is ideal.

## Requirements
### Server & Peer Hosts
- IPV4 address
- wireguard
- Linux
    - This was tested on Debian 12 but should work on any distro.
### Server Host Only
- iptables
- iptables-persistent
- Port 51820 opened on your firewalls (both external and internal)

Aptitude package manager would be able to install these using:
```
# Wireguard peer host
apt install wireguard

# Wireguard server host
apt install wireguard iptables iptables-persistent
```

## Installation
Clone the repository or download the latest release. If downloading the latest release, you'll need to unzip it before using it.

## Setting up your environment file
Both scripts source the `.env` file present in the repository. Most users will only need to modify `PHYSICAL_INTERFACE` and `SERVER_PUBLIC_IP`.

### PHYSICAL_INTERFACE
The `.env` file has the `PHYSICAL_INTERFACE` set to nothing by default. You can find the correct value by running the command `ip addr`:

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

Here, my physical interface is actually `ens18` so you should change the `PHYSICAL_INTERFACE` variable in `.env` to `ens18`.

### SERVER_PUBLIC_IP
The `.env` file has the `SERVER_PUBLIC_IP` set to nothing by default. This should just be the public IP of the server host. You can find this in many different ways, one way is to run the command `curl ifconfig.io -4`:

```
root@pelican-panel-proxy:~/wireguard-tunnel-forwarding-master# curl ifconfig.io -4
185.87.65.43
```

From this example, we see the public IP of the server is `185.87.65.43`. Alternatively, if you've bought a VPS, this can easily be found on their control panels or set-up email.

## Running the Scripts
### Tunnel Install
Run `./tunnel-install.sh` on the **wireguard server host**. Your configs are automatically populated in `/etc/wireguard/wg0.conf` using information from `.env`. You will also get a multiline command that should be pasted into the peer host to set up the necessary configs for connection to the wireguard server. This is also saved under `current-client-config.txt` and will be automatically updated each time you run `tunnel-install.sh`


A successful run should look like this:

```
root@wireguard-server-host:~/wireguard-tunnel-forwarding# ./tunnel-install.sh
Enabling IPV4 forwarding...
Generating server and peer keys...
Generating wireguard server config...
Wireguard server config built!

###############################################
# PASTE THE COMMAND BELOW INTO YOUR PEER HOST #
###############################################

echo "[Interface]
Address = 10.0.0.2/24
PrivateKey = 6PioMcuAvo1J7grI53nTgieikJkfg3Uzz6HILLeq2Vo=

[Peer]
PublicKey = GDSWDQq8BYTCwM5DwtpRT66RIoKd6DCFqwevsJ6vQUY=
Endpoint = 185.87.65.43:51820
AllowedIPs = 0.0.0.0/0
PersistentKeepalive = 25" > /etc/wireguard/wg0.conf

###############################################
#                     END                     #
###############################################
```
> [!WARNING]
> If you're using TMUX, do not copy this from the window as the formatting will be wrong. Either come out of TMUX and copy it or open the generate `current-client-config.txt` in a text reader such as `vim`, `nano`, `less` etc...

Assuming both hosts use systemd and all necessary commands have been run, you can enable the service by running `systemctl enable --now wg-quick@wg0` on both hosts. Then, `systemctl status wg-quick@wg0` should show them both running without errors.

On the peer, you should now be able to query the IP and get wireguard server hosts public IP. `example: curl ifconfig.io -4`

### Port Management
To open ports, run `./manage-port.sh -h` on the **wireguard server host** to see your options. As an example, this is what opening TCP & UDP port 42420 looks like:

```
root@wireguard-server-host:~/wireguard-tunnel-forwarding-master# ./manage-port.sh -p 42420
++ iptables -t nat -A PREROUTING -i ens18 -p tcp --dport 42420 -j DNAT --to-destination 10.0.0.2:42420
++ iptables -A FORWARD -i wg0 -o ens18 -p tcp --sport 42420 -s 10.0.0.2 -j ACCEPT
++ iptables -A FORWARD -i ens18 -o wg0 -p tcp --dport 42420 -d 10.0.0.2 -j ACCEPT
++ set +o xtrace
root@wireguard-server-host:~/wireguard-tunnel-forwarding-master# ./manage-port.sh -up 42420
++ iptables -t nat -A PREROUTING -i ens18 -p udp --dport 42420 -j DNAT --to-destination 10.0.0.2:42420
++ iptables -A FORWARD -i wg0 -o ens18 -p udp --sport 42420 -s 10.0.0.2 -j ACCEPT
++ iptables -A FORWARD -i ens18 -o wg0 -p udp --dport 42420 -d 10.0.0.2 -j ACCEPT
++ set +o xtrace
```
