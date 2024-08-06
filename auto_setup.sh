# Utils functions

# Colors!!! :D
RED='\033[0;31m'
LGREEN='\033[1;32m'
YELLOW='\033[1;33m'
RESET='\033[0m'

function success {
    echo ""
    echo -e "*<===>*$LGREEN SUCCESS!$RESET $1 <===>*"
    echo ""
}

function skipped {
    echo ""
    echo -e "*<===>*$YELLOW SKIPPED!$RESET $1 <===>*"
    echo ""
}

function failed {
    echo ""
    echo -e "*<===>*$RED FAILED! $1 $RESET<===>*"
    echo ""
}

# Main code

# Preparing GTeam's VPNSetup folder in /etc
sudo mkdir -p /etc/gteam/vpnsetup/

# Get server's basic ip like hostname & ip
serverName=$(hostname)
serverID="${serverName:2:1}" # Just get the number if this is part of GTeam's network

netInterface=$(ip a show eth0)

# Test if selected network interface is valid (has an ipv4/v6), else ask while the provided net interface is not valid
if [[ $netInterface == *"inet"* ]]; then
	netInterface="eth0"
else
	if [ ! -f /etc/gteam/vpnsetup/netInterface.srv-info ]; then
		while [[ $netInterface == "" ]];
		do
			read -p "*<===>* It seems like the network interface 'eth0' does not exists. What interface should we use ? |: " netInterface
			# Check that this interface exists
			netInterface=$(ip a show $netInterface)
			if [[ $netInterface == *"inet"* ]]; then
				printf "$netInterface" > /etc/gteam/vpnsetup/netInterface.srv-info
			else
				netInterface=""
			fi
		done
	else
		netInterface=$(sudo cat /etc/gteam/vpnsetup/netInterface.srv-info)
	fi
fi

if [[ $serverID = '^[0-9]+$' ]] && ( $serverID < 255 ); then
	echo "This server is part of GTeam's Network."
else
	if [ ! -f /etc/gteam/vpnsetup/serverID.srv-info ]; then
		while ! [[ $serverID =~ ^[0-9]+$ && ( $serverID > 255 ) ]];
		do
  		read -p "*<===>* Since this server is not part of GTeam's network, please enter an ID (for exemple if this is your first server, put 1, if its your fifth put 5, ect...) |: " serverID
		done
		printf "$serverID" > /etc/gteam/vpnsetup/serverID.srv-info
	else
		serverID=$(sudo cat /etc/gteam/vpnsetup/serverID.srv-info)
	fi
fi

serverIP=$(curl ifconfig.me)

# To clean things up
#clear

echo "                            ██████╗████████╗███████╗ █████╗ ███╗   ███╗             
                           ██╔════╝╚══██╔══╝██╔════╝██╔══██╗████╗ ████║             
                           ██║  ███╗  ██║   █████╗  ███████║██╔████╔██║             
                           ██║   ██║  ██║   ██╔══╝  ██╔══██║██║╚██╔╝██║             
                           ╚██████╔╝  ██║   ███████╗██║  ██║██║ ╚═╝ ██║             
                            ╚═════╝   ╚═╝   ╚══════╝╚═╝  ╚═╝╚═╝     ╚═╝             
                                                                                    
               ██╗   ██╗██████╗ ███╗   ██╗███████╗███████╗████████╗██╗   ██╗██████╗ 
               ██║   ██║██╔══██╗████╗  ██║██╔════╝██╔════╝╚══██╔══╝██║   ██║██╔══██╗
               ██║   ██║██████╔╝██╔██╗ ██║███████╗█████╗     ██║   ██║   ██║██████╔╝
               ╚██╗ ██╔╝██╔═══╝ ██║╚██╗██║╚════██║██╔══╝     ██║   ██║   ██║██╔═══╝ 
                ╚████╔╝ ██║     ██║ ╚████║███████║███████╗   ██║   ╚██████╔╝██║     
                 ╚═══╝  ╚═╝     ╚═╝  ╚═══╝╚══════╝╚══════╝   ╚═╝    ╚═════╝ ╚═╝      [SRV-$serverID]"

echo ""
echo "*<==================>* GTeam's VPNSetup Script v0007 (5th August, 2024) *<==================>*"
echo ""

# What should we do???!
echo "*<===>* 1 | Automatically setup WireGuard"
echo "*<===>* 2 | Automatically setup OpenVPN"
echo "*<===>* 3 | Add peer to WireGuard and auto generate client config"
echo "*<===>* 4 | Remove existing peer from WireGuard"
echo "*<===>* 5 | Run OpenVPN manager script. (Add/Remove users for OpenVPN)"
read -p "" mode

if [[ $mode == 1 ]]; then

	read -p "*<===>* What port should we use for WireGuard ? |: " -e -i 51820 wireguardPort
	read -p "*<===>* What is the server's main ip address ? (IPv4/IPv6) |: " -e -i $serverIP serverIP
	read -p "*<===>* What's DNS server should we use ? |: " -e -i "1.1.1.1" dnsServer
	read -p "*<===>* Do you want to reset and revoke all existing WireGuard users ? (y/N) |: " -e -i "y" resetUsers
	read -p "*<===>* Do you want to automatically setup UFW rules for WireGuard ? (y/N) |: " -e -i "y" autoSetupUFW
	read -p "*<===>* If you want to keep an already existing WireGuard server public key, please put WireGuard server's private key here, else leave this blank |: " customPrivateKey

	echo ""
	echo "*<==================>*"
	echo "  WireGuard Summary"
	echo ""
	echo "* Port: $wireguardPort"
	echo "* IP: $serverIP"
	echo "* DNS: $dnsServer"
	echo "* Reset users: $resetUsers"
	echo "* Auto-setup UFW: $autoSetupUFW"
	echo "* Private key: $privateKey"
	echo "*<==================>*"
	echo ""
	read -p "*<===>* Proceed with WireGuard installation ? (y/N) |: " -e -i "y" installWireguard

	if [ "${installWireguard,,}" = "y" ]; then

		if [ "${resetUsers,,}" = "y" ]; then
			sudo rm -rf /etc/gteam/vpnsetup/cfg/wg/
		fi

		sudo rm -rf /etc/gteam/vpnsetup/*.wg-info

		printf "$wireguardPort" > /etc/gteam/vpnsetup/port.wg-info
		printf "$serverIP" > /etc/gteam/vpnsetup/ip.wg-info
		printf "$dnsServer" > /etc/gteam/vpnsetup/dns.wg-info

		# WireGuard preped
		success "WireGuard prepared!"

		# Check and update APT
		read -p "*<===>* Proceed with apt update, upgrade & autoremove ? (y/N) |: " -e -i "y" proceedApt

		if [ "${proceedApt,,}" = "y" ]; then
			sudo apt update && sudo apt upgrade -y && sudo apt autoremove -y
			success "apt updated, upgraded and autoremoved!"
		else
			skipped "apt was not updated nor upgrade nor autoremoved."
		fi

		# Install WireGuard & (maybe) UFW
		sudo apt install wireguard -y

		if [[ $(dpkg -l | grep wireguard) == "" ]]; then
			failed "WireGuard couldn't be installed properly."
			exit 5
		else
			success "WireGuard installed correctly"
		fi

		if [ "${autoSetupUFW,,}" = "y" ]; then
			sudo apt install ufw -y
			if [[ $(dpkg -l | grep wireguard) == "" ]]; then
				failed "UFW couldn't be installed properly."
				exit 5
			else
				success "UFW installed correctly!"
			fi
		else
			skipped "UFW was not installed."
		fi

		# Generate private & public keys
		if [ "$customPrivateKey" == "" ]; then
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
		PostUp = ufw route allow in on tun_wgd out on $netInterface
		PostUp = iptables -t nat -I POSTROUTING -o $netInterface -j MASQUERADE
		PostUp = ip6tables -t nat -I POSTROUTING -o $netInterface -j MASQUERADE
		PreDown = ufw route delete allow in on tun_wgd out on $netInterface
		PreDown = iptables -t nat -D POSTROUTING -o $netInterface -j MASQUERADE
		PreDown = ip6tables -t nat -D POSTROUTING -o $netInterface -j MASQUERADE
		ListenPort = $wireguardPort
		PrivateKey = $privateKey"

		printf "$tunwgd_conf" > /etc/wireguard/tun_wgd.conf
		touch /etc/gteam/vpnsetup/usedIPs.wg-info

		sudo systemctl enable wg-quick@tun_wgd.service
		sudo systemctl start wg-quick@tun_wgd.service
		
		if [[ $(sudo systemctl status wg-quick@tun_wgd.service | grep active) == "" ]]; then
			failed "WireGuard couldn't be configured and started properly."
			exit 5
		else
			success "WireGuard configured and started correctly!"
		fi

		if [ "${autoSetupUFW,,}" = "y" ]; then
			sudo ufw allow in on $netInterface from any to $serverIP port 443 proto udp
			sudo ufw allow in on $netInterface from any to $serverIP port 22 proto tcp
			echo "y" | sudo ufw enable
			
			if [[ $(sudo ufw status | grep "Status: active") == "" ]]; then
				failed "UFW couldn't be configured and started properly."
				exit 5
			else
				success "UFW configured and started correctly!"
			fi
		else
			skipped "UFW was not configured."
		fi

		# Tune sysctl to allow ipv4 & ipv6 forwarding
		sudo sysctl -w net.ipv4.ip_forward=1
		sudo sysctl -w net.ipv6.conf.all.forwarding=1
		sudo sysctl -p
		
		if [[ $(sudo sysctl -p | grep "net.ipv4.ip_forward=1") == "" ]]; then
			failed "sysctl couldn't be configured properly."
			exit 5
		elif [[ $(sudo sysctl -p | grep "net.ipv6.conf.all.forwarding=1") == "" ]]; then
			failed "sysctl couldn't be configured properly."
			exit 5
		else
			success "sysctl configured correctly!"
		fi

		success "WireGuard setup finished!"

	else
		failed "WireGuard installation cancelled by user."
		exit 5
	fi

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
