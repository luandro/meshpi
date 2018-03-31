#! /bin/bash
#
# Raspberry Pi network configuration / AP, MESH install script
# Author: Luandro
# Contributors: Sarah Grant, Mark Hansen, Matthias Strubel, Danja Vasiliev
# took guidance from a script by Paul Miller : https://dl.dropboxusercontent.com/u/1663660/scripts/install-rtl8188cus.sh
# Updated 22 March 2018
#
# TO-DO
# - allow a selection of radio drivers
# - fix addressing to avoid collisions below w/avahi
# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #





# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
# first find out if this is RPi3 or not, based on revision code
# reference: http://www.raspberrypi-spy.co.uk/2012/09/checking-your-raspberry-pi-board-version/
REV="$(cat /proc/cpuinfo | grep 'Revision' | awk '{print $3}')"





# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
# LOAD CONFIG FILE WITH USER OPTIONS
#
#  READ configuration file
. ./meshpi.config





# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
# CHECK USER PRIVILEGES
(( `id -u` )) && echo "This script *must* be ran with root privileges, try prefixing with sudo. i.e sudo $0" && exit 1





# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
# BEGIN INSTALLATION PROCESS
#

clear
echo "////////////////////////"
echo "// Welcome to Mesh Pi!"
echo "// ~~~~~~~~~~~~~~~~~~~~"
echo ""

# echo "Let's find out what is your meshin USB"
# iw phy  | grep phy
# echo -n " "
read -p "This installation script will install the latest arm version of node.js with a chatroom, set up a wireless access point and captive portal, and provide the option of configuring a BATMAN-ADV mesh point. Make sure you have one (or two, if installing the additional mesh point) USB wifi radios connected to your Raspberry Pi before proceeding. Press any key to continue..."
echo ""
clear




# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
# CHECK THAT REQUIRED RADIOS ARE AVAILABLE FOR AP & MESH POINT [IF SELECTED]
#
# check that iw list does not fail with 'nl80211 not found'
echo -en "Checking that USB wifi radio is available for access point..."
readarray IW < <(iw dev | awk '$1~"phy#"{PHY=$1}; $1=="Interface" && $2~"wlan"{WLAN=$2; sub(/#/, "", PHY); print PHY " " WLAN}')
if [[ -z $IW ]] ; then
	echo -en "[FAIL]\n"
	echo "Warning! Wireless adapter not found! Please plug in a wireless radio after installation completes and before reboot."
	echo "Installation process will proceed in 5 seconds..."
	sleep 5
else
	echo -en "[OK]\n"
fi

# now check that iw list finds a radio other than wlan0 if mesh point option was set to 'y' in config file
case $DO_SET_MESH in
	[Yy]* )
		echo -en "Checking that USB wifi radio is available for mesh point..."
		readarray IW < <(iw dev | awk '$1~"phy#"{PHY=$1}; $1=="Interface" && $2!="wlan0"{WLAN=$2; sub(/#/, "", PHY); print PHY " " WLAN}')

		if [[ -z $IW ]] ; then
			echo -en "[FAIL]\n"
			echo "Warning! Second wireless adapter not found! Please plug in an addition wireless radio after installation completes and before reboot."
			echo "Installation process will proceed in 5 seconds..."
			sleep 5
		else
			echo -en "[OK]\n"
		fi
;;
esac






# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
# SOFTWARE INSTALL
#
# update the packages (moved to PiBakery)
# echo "Updating apt-get and installing iw package for network interface configuration and batctl to manage batman adv..."
# apt-get update && apt-get install -y iw batctl
echo ""
echo "Loading the meshpi configuration file..."

# Check if configuration exists, ask for overwriting
if [ -e /etc/meshpi.config ] ; then
        read -p "Older config file found! Overwrite? (y/n) [N]" -e $q
        if [ "$q" == "y" ] ; then
                echo "...overwriting"
                copy_ok="yes"
        else
                echo "...not overwriting. Re-reading found configuration file..."
                . /etc/meshpi.config
        fi
else
        copy_ok="yes"
fi

# copy config file to /etc
[ "$copy_ok" == "yes" ] && cp meshpi.config /etc

# install node.js (moved to PiBakery)
# echo "Installing latest Node.js for arm..."
# wget http://node-arm.herokuapp.com/node_latest_armhf.deb
# dpkg -i node_latest_armhf.deb
# echo ""

# install chat room
# echo "Installing chat room..."
# go back to our meshpi directory
cd "$(dirname $(readlink -f $0))"

# download meshpi app dependencies
# npm install
# npm install -g nodemon





# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
# DISABLE DHCPCD SINCE WE ARE RELYING ON STATIC IPs IN A CLOSED NETWORK
#
systemctl disable dhcpcd
systemctl enable networking





# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
# CONFIGURE AN ACCESS POINT WITH CAPTIVE PORTAL
#

clear
echo "Configuring Access Point..."
echo ""

# install required packages (moved to PiBakery)
# echo ""
# echo -en "Installing bridge-utils, hostapd and dnsmasq..."
# apt-get install -y bridge-utils hostapd dnsmasq
# echo -en "[OK]\n"

# backup the existing interfaces file
echo -en "Creating backup of network interfaces configuration file..."
cp /etc/network/interfaces /etc/network/interfaces.bak
rc=$?
if [[ $rc != 0 ]] ; then
		echo -en "[FAIL]\n"
	exit $rc
else
	echo -en "[OK]\n"
fi		

# create hostapd init file
echo -en "Creating default hostapd file..."
cat <<EOF > /etc/default/hostapd
DAEMON_CONF="/etc/hostapd/hostapd.conf"
EOF
	rc=$?
	if [[ $rc != 0 ]] ; then
			echo -en "[FAIL]\n"
		echo ""
		exit $rc
	else
		echo -en "[OK]\n"
	fi





# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
# CONFIGURE A MESH POINT?

clear
echo "Checking whether to configure mesh point or not..."





# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
# 	DO CONFIGURE MESH POINT
#

case $DO_SET_MESH in
	[Yy]* )
		clear
		echo "Configuring Raspberry Pi as a BATMAN-ADV mesh point..."
		echo ""
		echo "Enabling the batman-adv kernel module..."
		# add the batman-adv module to be started on boot
		sed -i '$a batman-adv' /etc/modules
		modprobe batman-adv;

		# pass custom params into mesh startup script
		sed -i "s/MTU/$MTU/" scripts/meshpi_mesh.sh
		sed -i "s/SSID/$MESH_SSID/" scripts/meshpi_mesh.sh
		sed -i "s/CELL_ID/$CELL_ID/" scripts/meshpi_mesh.sh
		sed -i "s/CHAN/$MESH_CHANNEL/" scripts/meshpi_mesh.sh

		# configure dnsmasq
		echo -en "Creating dnsmasq configuration file..."
		cat <<EOF > /etc/dnsmasq.conf
interface=br0
address=/#/$BRIDGE_IP
address=/apple.com/0.0.0.0
dhcp-range=$BR_DHCP_START,$BR_DHCP_END,$DHCP_NETMASK,$DHCP_LEASE
EOF
	rc=$?
	if [[ $rc != 0 ]] ; then
    		echo -en "[FAIL]\n"
		echo ""
		exit $rc
	else
		echo -en "[OK]\n"
	fi

		# create new /etc/network/interfaces
		echo -en "Creating new network interfaces with your settings..."
		cat <<EOF > /etc/network/interfaces
auto lo
iface lo inet loopback

allow-hotplug eth0
auto eth0
iface eth0 inet dhcp

auto wlan0
iface wlan0 inet static
address $AP_IP
netmask $AP_NETMASK

auto br0
iface br0 inet static
address $BRIDGE_IP
netmask $BRIDGE_NETMASK
bridge_ports bat0 wlan0
bridge_stp off

iface default inet dhcp
EOF
		rc=$?
		if [[ $rc != 0 ]] ; then
		    	echo -en "[FAIL]\n"
			echo ""
			exit $rc
		else
			echo -en "[OK]\n"
		fi

		# create hostapd configuration with user's settings
		echo -en "Creating hostapd.conf file..."
		cat <<EOF > /etc/hostapd/hostapd.conf
interface=ap0
bridge=br0
driver=$RADIO_DRIVER
country_code=$AP_COUNTRY
ctrl_interface=/var/run/hostapd
ctrl_interface_group=0
ssid=$AP_SSID
hw_mode=g
channel=$AP_CHAN
beacon_int=100
auth_algs=1
wpa=0
ap_isolate=1
macaddr_acl=0
wmm_enabled=1
ieee80211n=1
EOF
		rc=$?
		if [[ $rc != 0 ]] ; then
			echo -en "[FAIL]\n"
			exit $rc
		else
			echo -en "[OK]\n"
		fi

		# COPY OVER START UP SCRIPTS
		echo ""
		echo "Adding startup scripts to init.d..."
		cp scripts/meshpi_ap.sh /etc/init.d/meshpi_ap
		chmod 755 /etc/init.d/meshpi_ap
		update-rc.d meshpi_ap defaults
		cp scripts/meshpi_mesh.sh /etc/init.d/meshpi_mesh
		chmod 755 /etc/init.d/meshpi_mesh
		update-rc.d meshpi_mesh defaults
	;;





# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
# 	ACCESS POINT ONLY
#

	[Nn]* ) 
	# if no mesh point is created, set up network interfaces, hostapd and dnsmasq to operate without a bridge
		clear
		
		# configure dnsmasq
		echo -en "Creating dnsmasq configuration file..."
		cat <<EOF > /etc/dnsmasq.conf
interface=wlan0
address=/#/$AP_IP
address=/apple.com/0.0.0.0
dhcp-range=$AP_DHCP_START,$AP_DHCP_END,$DHCP_NETMASK,$DHCP_LEASE
EOF
		rc=$?
		if [[ $rc != 0 ]] ; then
	    		echo -en "[FAIL]\n"
			echo ""
			exit $rc
		else
			echo -en "[OK]\n"
		fi

		# create new /etc/network/interfaces
		echo -en "Creating new network interfaces with your settings..."
		cat <<EOF > /etc/network/interfaces
auto lo
iface lo inet loopback

allow-hotplug eth0
auto eth0
iface eth0 inet dhcp

auto wlan0
iface wlan0 inet static
address $AP_IP
netmask $AP_NETMASK

iface default inet dhcp
EOF
		rc=$?
		if [[ $rc != 0 ]] ; then
		    	echo -en "[FAIL]\n"
			echo ""
			exit $rc
		else
			echo -en "[OK]\n"
		fi

		# create hostapd configuration with user's settings
		echo -en "Creating hostapd.conf file..."
		cat <<EOF > /etc/hostapd/hostapd.conf
interface=wlan0
driver=$RADIO_DRIVER
country_code=$AP_COUNTRY
ctrl_interface=/var/run/hostapd
ctrl_interface_group=0
ssid=$AP_SSID
hw_mode=g
channel=$AP_CHAN
auth_algs=1
wpa=0
ap_isolate=1
macaddr_acl=0
wmm_enabled=1
ieee80211n=1
EOF
		rc=$?
		if [[ $rc != 0 ]] ; then
			echo -en "[FAIL]\n"
			exit $rc
		else
			echo -en "[OK]\n"
		fi

		# COPY OVER START UP SCRIPTS
		echo ""
		echo "Adding startup scripts to init.d..."
		cp scripts/meshpi_ap.sh /etc/init.d/meshpi_ap
		chmod 755 /etc/init.d/meshpi_ap
		update-rc.d meshpi_ap defaults
	;;
esac





# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
# COPY OVER THE ACCESS POINT START UP SCRIPT + enable services
#

clear
update-rc.d hostapd remove
update-rc.d dnsmasq enable

read -p "Do you wish to reboot now? [N] " yn
	case $yn in
		[Yy]* )
			reboot;;
		[Nn]* ) exit 0;;
	esac
