# To clean things up
clear

# Get server's location and basic infos
serverName=$(hostname)
serverID="${serverName:2:1}" # Just get the number if this is part of GTeam's network

if [[ $serverID =~ ^-?[0-9]+$ ]]; then
	echo "Server is part of GTeam's Network"
else
  read -p "*==========* Since this server is not part of GTeam's network, please put an ID (for exemple if this is your first server, put 1, if its your fifth put 5, ect...) |: " serverID
fi

echo " ██████╗████████╗███████╗ █████╗ ███╗   ███╗
██╔════╝╚══██╔══╝██╔════╝██╔══██╗████╗ ████║
██║  ███╗  ██║   █████╗  ███████║██╔████╔██║
██║   ██║  ██║   ██╔══╝  ██╔══██║██║╚██╔╝██║
╚██████╔╝  ██║   ███████╗██║  ██║██║ ╚═╝ ██║
 ╚═════╝   ╚═╝   ╚══════╝╚═╝  ╚═╝╚═╝     ╚═╝ [SRV-$serverID]"

echo ""
echo "*====================* GTeam's Host Setup Script (HSS) v0005 (31/07/2024) *====================*"

# What should we do???!
echo "*==========* What would you like to do today ?"
echo "*=====* 1 | Automatically setup WireGuard"
echo "*=====* 2 | Automatically setup OpenVPN"
echo "*=====* 3 | Add peer to WireGuard and auto generate client config"
echo "*=====* 4 | Remove existing peer from WireGuard"
echo "*=====* 5 | Run OpenVPN manager script."
read -p "*==========* Soooo what do you want to do ? |: " mode

if [[ $mode == 1 ]]; then

	read -p "*==========* What's the DNS resolvers IP ? |: " dnsServer
	read -p "*==========* What is the server's main ip address ? (IPv4/IPv6) |: " serverIP
	read -p "*==========* If you want to keep an already existing WireGuard server public key, please put it here, else leave it blank |: " customPrivateKey

	sudo rm -rf /etc/wireguard/cfg

	sudo mkdir /etc/wireguard/
	sudo mkdir /etc/wireguard/cfg

	sudo rm -rf /etc/wireguard/*.info

	printf "$dnsServer" > /etc/wireguard/dns.info
	printf "$serverIP" > /etc/wireguard/ip.info

	# Fix "cant resolve hostname" ahhh error
	if grep -q "$serverName" "/etc/hosts"; then
		echo ""
	else
		printf "127.0.0.1       $serverName" >> /etc/hosts
		printf "::1       $serverName" >> /etc/hosts
	fi

	# Check and update APT
	sudo apt update && sudo apt upgrade -y && sudo apt autoremove -y
	echo "*====================* apt update, apt upgrade and apt autoremove were ran! *====================*"

	# Install WireGuard & UFW and set it up
	sudo apt install wireguard ufw -y

	# Generate private & public keys
	if [[ "$customPrivateKey" == "" ]]; then
		privateKey=$(wg genkey | sudo tee /etc/wireguard/private.key)
	else
		privateKey="$customPrivateKey
		"
		printf "$privateKey" > /etc/wireguard/private.key
	fi

	sudo chmod go= /etc/wireguard/private.key
	publicKey=$(sudo cat /etc/wireguard/private.key | wg pubkey | sudo tee /etc/wireguard/public.key)

	# Define WireGuard's tunnel IPv4 & IPv6
	tunwgd_ipv4="10.$serverID.1"
	tunwgd_ipv6="fe0$serverID:0001:FFFF"

	# WireGuard config (tun_wgd.conf)
	tunwgd_conf="
	[Interface]
	Address = $tunwgd_ipv4.1/24
	Address = $tunwgd_ipv6::1/64
	DNS = $dnsServer
	SaveConfig = true
	PostUp = ufw route allow in on tun_wgd out on eth0
	PostUp = iptables -t nat -I POSTROUTING -o eth0 -j MASQUERADE
	PostUp = ip6tables -t nat -I POSTROUTING -o eth0 -j MASQUERADE
	PreDown = ufw route delete allow in on tun_wgd out on eth0
	PreDown = iptables -t nat -D POSTROUTING -o eth0 -j MASQUERADE
	PreDown = ip6tables -t nat -D POSTROUTING -o eth0 -j MASQUERADE
	ListenPort = 443
	PrivateKey = $privateKey"

	printf "$tunwgd_conf" > /etc/wireguard/tun_wgd.conf
	touch /etc/wireguard/usedIPs.info

	sudo systemctl enable wg-quick@tun_wgd.service
	sudo systemctl start wg-quick@tun_wgd.service
	echo "*====================* WireGuard tunnel is up! Public key: $publicKey *====================*"

	sudo ufw allow in on eth0 from any to $serverIP port 443 proto udp
	sudo ufw allow in on eth0 from any to $serverIP port 22 proto tcp
	sudo ufw enable
	echo "*====================* UFW is ready! *====================*"

	# Tune sysctl to allow ipv4 & ipv6 forwarding
	sudo sysctl -w net.ipv4.ip_forward=1
	sudo sysctl -w net.ipv6.conf.all.forwarding=1
	sudo sysctl -p
	echo "*====================* sysctl tuned! *====================*"

elif [[ $mode == 2 ]]; then

	read -p "*==========* What is the server's main ip address ? (IPv4/IPv6) |: " serverIP
  read -p "*===================* What should be the UDP port ? |: " -e -i 587 openvpn_port_udp
  read -p "*===================* What should be the TCP port ? |: " -e -i 443 openvpn_port_tcp
	echo "Downloading OpenVPN installation script..."

	sudo rm openvpn-install.sh

	wget https://raw.githubusercontent.com/GTeamx/openvpn-install/main/openvpn-install.sh

	chmod +x openvpn-install.sh

	AUTO_INSTALL=y APPROVE_IP=y IPV6_SUPPORT=y PORT_CHOICE=1 PROTOCOL_CHOICE=1 DNS=3 COMPRESSION_ENABLED=n CUSTOMIZE_ENC=n CLIENT=root PASS=1 SERVER_ID=$serverID PORT_UDP=$openvpn_port_udp PORT_TCP=$openvpn_port_tcp ./openvpn-install.sh

	sudo systemctl stop openvpn@server
	sudo systemctl stop openvpn

	sudo cp /etc/openvpn/server.conf /etc/openvpn/TCP.conf
	sudo cp /etc/openvpn/server.conf /etc/openvpn/UDP.conf

	sed -i "s/1194/$openvpn_port_tcp/g" /etc/openvpn/TCP.conf
	sed -i 's/udp6/tcp6/g' /etc/openvpn/TCP.conf
	sed -i 's/dev tun/dev tun_tcp/g' /etc/openvpn/TCP.conf
	sed -i "s/10.8.0.0/10.$serverID.2.0/g" /etc/openvpn/TCP.conf
	sed -i "s/fd42:42:42:42/fe0$serverID:0002:FFFF/g" /etc/openvpn/TCP.conf
	sed -i "s/\/112/\/64/g" /etc/openvpn/TCP.conf
	sed -i 's/AES-128-GCM/CHACHA20-POLY1305/g' /etc/openvpn/TCP.conf

	sed -i "s/1194/$openvpn_port_udp/g" /etc/openvpn/UDP.conf
	sed -i 's/dev tun/dev tun_udp/g' /etc/openvpn/UDP.conf
	sed -i "s/10.8.0.0/10.$serverID.3.0/g" /etc/openvpn/UDP.conf
	sed -i "s/fd42:42:42:42/fe0$serverID:0003:FFFF/g" /etc/openvpn/UDP.conf
	sed -i "s/\/112/\/64/g" /etc/openvpn/UDP.conf
	sed -i 's/AES-128-GCM/CHACHA20-POLY1305/g' /etc/openvpn/UDP.conf

  printf "$openvpn_port_tcp" > /etc/openvpn/tcp_port.info
  printf "$openvpn_port_udp" > /etc/openvpn/udp_port.info

	sudo rm -rf /etc/openvpn/server.conf
	touch /etc/openvpn/server.conf

	sudo ufw allow in on eth0 from any to $serverIP port $openvpn_port_tcp proto tcp
	sudo ufw allow in on eth0 from any to $serverIP port $openvpn_port_udp proto udp

	sudo ufw route allow in on tun_tcp out on eth0
	sudo ufw route allow in on tun_udp out on eth0

	sudo systemctl enable openvpn@TCP
	sudo systemctl enable openvpn@UDP

	sudo systemctl start openvpn@TCP
	sudo systemctl start openvpn@UDP

elif [[ $mode == 3 ]]; then

	if [ ! -f /etc/wireguard/ip.info ]; then
		echo "*====================* You need to use the WireGuard setup function first! *====================*"
	else
		tunwgd_publicKey=$(sudo cat /etc/wireguard/public.key)
		serverDNS=$(sudo cat /etc/wireguard/dns.info)
		serverIP=$(sudo cat /etc/wireguard/ip.info)

		tunwgd_conf_presetClient_privateKey=$(wg genkey)
		printf "$tunwgd_conf_presetClient_privateKey" > /etc/wireguard/temp.key
		tunwgd_conf_presetClient_publicKey=$(sudo cat /etc/wireguard/temp.key | wg pubkey)
		sudo rm -rf /etc/wireguard/temp.key/etc/wireguard/temp.key

		tunwgd_conf_ipNumber=0
		testIpNumber=2

		while [ $tunwgd_conf_ipNumber == 0 ]
		do
			if grep -q "10.$serverID.1.$testIpNumber" /etc/wireguard/usedIPs.info; then
				testIpNumber=$((testIpNumber + 1))
			else
				tunwgd_conf_ipNumber=$testIpNumber
			fi
		done

		tunwgd_conf_presetClient="
		[Interface]
		PrivateKey = $tunwgd_conf_presetClient_privateKey
		Address = 10.$serverID.1.$tunwgd_conf_ipNumber/32, fe0$serverID:1:ffff::$tunwgd_conf_ipNumber/128
		DNS = $serverDNS
		PostUp = powershell.exe -Command \"& { Add-DnsClientNrptRule -Comment 'tun_wgd' -Namespace '.' -NameServers $serverDNS }\"
		PostDown = powershell.exe -Command \"& { Get-DnsClientNrptRule | where Comment -eq 'tun_wgd' | foreach { Remove-DnsClientNrptRule -Name $_.Name -Force } }\"

		[Peer]
		PublicKey = $tunwgd_publicKey
		AllowedIPs = 0.0.0.0/5, 8.0.0.0/7, 11.0.0.0/8, 12.0.0.0/6, 16.0.0.0/4, 32.0.0.0/3, 64.0.0.0/2, 128.0.0.0/3, 160.0.0.0/5, 168.0.0.0/6, 172.0.0.0/12, 172.32.0.0/11, 172.64.0.0/10, 172.128.0.0/9, 173.0.0.0/8, 174.0.0.0/7, 176.0.0.0/4, 192.0.0.0/9, 192.128.0.0/11, 192.160.0.0/13, 192.169.0.0/16, 192.170.0.0/15, 192.172.0.0/14, 192.176.0.0/12, 192.192.0.0/10, 193.0.0.0/8, 194.0.0.0/7, 196.0.0.0/6, 200.0.0.0/5, 208.0.0.0/4, 224.0.0.0/3, ::/1, 8000::/1
		Endpoint = $serverIP:443
		"

		wg set tun_wgd peer $tunwgd_conf_presetClient_publicKey allowed-ips 10.$serverID.1.$tunwgd_conf_ipNumber/32,fe0$serverID:1:ffff::$tunwgd_conf_ipNumber/128

		printf "10.$serverID.1.$tunwgd_conf_ipNumber/32, fe0$serverID:1:ffff::$tunwgd_conf_ipNumber/128\n" >> /etc/wireguard/usedIPs.info

		read -p "*==========* What should be the config's name ? (put the name of the person) |: " configName

		printf "$tunwgd_conf_presetClient" > /etc/wireguard/cfg/$configName.conf

		echo "*====================* WireGuard config created successfully! *====================*"

	fi

elif [[ $mode == 4 ]]; then

	count=1
	declare -A keys
	declare -A configs
	declare -A ips

	for configFile in /etc/wireguard/cfg/*
	do
		configFile_allowedIPs=$(sed '4!d' "$configFile")
		configFile_allowedIPs="${configFile_allowedIPs:12:128}"
		configFile_privateKey=$(sed '3!d' "$configFile")
		configFile_privateKey="${configFile_privateKey:15:64}"
		printf "$configFile_privateKey" > /etc/wireguard/temp.key
		configFile_publicKey=$(sudo cat /etc/wireguard/temp.key | wg pubkey)
		sudo rm -rf /etc/wireguard/temp.key/etc/wireguard/temp.key
		configs[$count]=$configFile
		keys[$count]=$configFile_publicKey
		configFile_allowedIPs=$(sed 's/\/32.*//' <<< $configFile_allowedIPs)
		ips[$count]=$configFile_allowedIPs
		echo "$count | $configFile | $configFile_allowedIPs"
		count=$((count + 1))
	done

	read -p "*==========* Which config would you like to revoke ? (ID) |: " configID

	wg set tun_wgd peer ${keys[$configID]} remove

	sed -i "/${ips[$configID]}/d" /etc/wireguard/usedIPs.info

	rm -rf ${configs[$configID]}

	echo "*====================* WireGuard config revoked successfully! *====================*"

elif [[ $mode == 5 ]]; then

	read -p "*==========* If you are ADDING a new client, please provide the name you'll put so we can tweak the config properly |: " configName
	read -p "*==========* If you are REMOVING a client, please provide the name you'll put so we can tweak the config properly |: " configNameRemove

	./openvpn-install.sh

	if [[ "$configName" == "" ]]; then
		echo "*====================* No config was tweaked (add). *====================*"
	else

    openvpn_port_udp=$(sudo cat /etc/openvpn/udp_port.info)
    openvpn_port_tcp=$(sudo cat /etc/openvpn/tcp_port.info)

		sudo cp /root/$configName.ovpn /root/$configName-TCP.ovpn
		sudo cp /root/$configName.ovpn /root/$configName-UDP.ovpn

		sudo rm -rf /root/$configName.ovpn
		touch /root/$configName.ovpn

		sed -i "s/1194/$openvpn_port_tcp/g" /root/$configName-TCP.ovpn
		sed -i 's/proto udp/proto tcp/g' /root/$configName-TCP.ovpn
		sed -i 's/dev tun/dev tun_tcp/g' /root/$configName-TCP.ovpn
		sed -i 's/AES-128-GCM/CHACHA20-POLY1305/g' /root/$configName-TCP.ovpn

		sed -i "s/1194/$openvpn_port_udp/g" /root/$configName-UDP.ovpn
		sed -i 's/dev tun/dev tun_udp/g' /root/$configName-UDP.ovpn
		sed -i 's/AES-128-GCM/CHACHA20-POLY1305/g' /root/$configName-UDP.ovpn

		tlscrypt=$(sudo cat /etc/openvpn/tls-crypt.key)

		printf "<tls-crypt>\n" >> /root/$configName-TCP.ovpn
		printf "$tlscrypt\n" >> /root/$configName-TCP.ovpn
		printf "</tls-crypt>" >> /root/$configName-TCP.ovpn

		printf "<tls-crypt>" >> /root/$configName-UDP.ovpn
		printf "$tlscrypt\n" >> /root/$configName-UDP.ovpn
		printf "</tls-crypt>" >> /root/$configName-UDP.ovpn

		echo "*====================* Config $configName.ovpn was added! *====================*"
	fi

	if [[ "$configNameRemove" == "" ]]; then
		echo "*====================* No config was tweaked (remove). *====================*"
	else
		sudo rm -rf /root/$configNameRemove*.ovpn
		echo "*====================* Config $configNameRemove.ovpn was removed! *====================*"
	fi

else
	echo "Unknown option"
fi