[//]: # (Main image, centered)
<p align="center">
  <img width="300" src="https://raw.githubusercontent.com/GTeamx/.github/main/assets/vpn-setup.png">
</p>

[//]: # (Main title, centered)
<h1 align="center">🔒 VPN-Setup 🔒</h1>

[//]: # (Shield.io badges, main basic stuff, centered)
<div align="center">

  <a href="">![GitHub Release](https://img.shields.io/github/v/release/GTeamx/VPNSetup?sort=date&display_name=tag&style=for-the-badge&label=Latest%20Release&color=55FFFF)</a>
  <a href="">![GitHub Downloads (all assets, latest release)](https://img.shields.io/github/downloads/GTeamx/VPNSetup/latest/total?sort=date&style=for-the-badge&label=Latest%20Downloads)</a>
  <a href="">![GitHub Downloads (all assets, all releases)](https://img.shields.io/github/downloads/GTeamx/VPNSetup/total?style=for-the-badge&label=Total%20Downloads)</a>
  <a href="">![GitHub License](https://img.shields.io/github/license/GTeamx/VPNSetup?style=for-the-badge)</a>
  <br>
  <a href="">![GitHub commits since latest release](https://img.shields.io/github/commits-since/GTeamx/VPNSetup/latest?sort=date&style=for-the-badge&label=commits%20since%20release)</a>
  <a href="">![GitHub commit activity (branch)](https://img.shields.io/github/commit-activity/m/GTeamx/VPNSetup/dev?style=for-the-badge&label='dev'%20branch%20commits)</a>
  <a href="">![GitHub commits difference between two branches/tags/commits](https://img.shields.io/github/commits-difference/GTeamx/VPNSetup?base=main&head=dev&style=for-the-badge&label='dev'%20ahead%20of%20'main'%20in%20commits)</a>
  <br>
  <a href="">![GitHub branch check runs](https://img.shields.io/github/check-runs/GTeamx/VPNSetup/main?style=for-the-badge&label='main'%20branch%20checks)</a>
  <a href="">![GitHub branch check runs](https://img.shields.io/github/check-runs/GTeamx/VPNSetup/dev?style=for-the-badge&label='dev'%20branch%20checks)</a>
  <a href="">![Static Badge](https://img.shields.io/badge/any_text-OpenVPN_Install-blue?style=for-the-badge&label=Dependencies)</a>
  <br>
  <a href="">![GitHub Repo stars](https://img.shields.io/github/stars/GTeamx/VPNSetup?style=for-the-badge)</a>
  <a href="">![GitHub watchers](https://img.shields.io/github/watchers/GTeamx/VPNSetup?style=for-the-badge)</a>
  <a href="">![GitHub forks](https://img.shields.io/github/forks/GTeamx/VPNSetup?style=for-the-badge)</a>
  <a href="">![Discord](https://img.shields.io/discord/1046001788106575912?style=for-the-badge&label=Discord)</a>

</div>

VPN-Setup aims to be an easy to use, efficient & a feature filled utility. This goes from automatically setting up VPN services such as WireGuard or OpenVPN, to manage users seamlessly, adding or revoking a client in just a few seconds.

## 📎 Special Credits

Special credits to Angristan for his [OpenVPN installation script](https://github.com/angristan/openvpn-install) that we are using to automatically setup OpenVPN and manage users with!

## ⬇️ Installation

First, download the latest release using wget on your server
```shell
wget -O auto_setup.sh https://github.com/GTeamx/VPNSetup/releases/latest/download/auto_setup.sh
```
Then make it exectuable by everyone using
```shell
chmod a+x auto_setup.sh
```
Finally, simply run the script by using
```shell
./auto_setup.sh
```

## 🌟 Features & Functionalities

- What does the WireGuard automatic install do for you ?:
  - Support IPv4 & IPv6
  - Port, DNS, apt, ufw & private key customization
  - Generate private & public server keys
  - Generate server config (with UFW & iptables)
  - Configure UFW (Firewall) for WireGuard & SSH
  - Tuning sysctl
  - Add & automatically generate client configs (with/without Windows DNS leak fix)
  - Remove existing WireGuard clients instantly
  - Uninstall & remove every trace of WireGuard

- What about OpenVPN ?:
  - Support IPv4 & IPv6
  - Port customization
  - Run both TCP & UDP modes simultaneously
  - Generate server configs automatically (TCP & UDP)
  - Configure UFW (Firewall) & iptables (TCP & UDP)
  - Tuning sysctl
  - Add & automatically generate configs (for both TCP & UDP)
  - Remove existing OpenVPN clients instantly
  - Uninstall & remove every trace of OpenVPN

- We do SOCKS5 too!:
  - *Comming soon!*

## 🔔 Releases/Updates

We highly recommand using the latest releases when possible as they might fix critical issues or errors. **VPN-Setup updates are ONLY RELEASED [HERE](https://github.com/GTeamx/VPNSetup)!**.

There a high chance you'll face errors and issues if your using the latest .sh file from the dev or main branch, please only use the released versions.

## 🚷 Errors/Bugs (Issues)

If you face any error or bugs during the usage of the script, please open an issue on our GitHub page. Providing sufficiant information to we are able to reproduce the error/issue on our side (provide the OS, released version that you were using, any other installed softwares, any "special" config changes that may or may not have done like in sysctl for exemple, ect...)

## 🔃 Contributing

Before contributing, please make sure that you follow our conventions (naming scheme, indentation) and that your code works! Make sure to also precise on what OS and what OS version you test were ran, provide any additionnal software installed where you ran your test (if applicable)

## 📜 License

This project is licensed under GNU General Public License v3.0 (GPL).
