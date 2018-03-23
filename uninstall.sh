#! /bin/bash
#
# meshpi uninstall script. Removes dnsmasq, hostapd, bridge-utils, batctl, iw. Does *not* yet remove Node.js. Deletes subnoes folder and files within.
# Luandro
# Updated 18 July 2017
#
# TO-DO
# - Remove node.js
#
# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #

# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
# CHECK USER PRIVILEGES
(( `id -u` )) && echo "This script *must* be ran with root privileges, try prefixing with sudo. i.e sudo $0" && exit 1


# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
# Uninstall meshpi
#
read -p "Do you wish to uninstall meshpi from your Raspberry Pi? [N] " yn
case $yn in
	[Yy]* )
		clear
		echo "Disabling the batman-adv kernel..."
		# remove the batman-adv module to be started on boot
		#sed -i '$a batman-adv' /etc/modules
		modprobe -r batman-adv;
		echo ""

		echo -en "Disabling hostapd and dnsmasq on boot..."
		update-rc.d hostapd disable
		update-rc.d dnsmasq disable

		# remove hostapd init file
		echo -en "Deleting default hostapd and configuration files..."
		rm /etc/default/hostapd
		rm /etc/hostapd/hostapd.conf
		echo -en "[OK]\n"

		# remove dnsmasq
		echo -en "Deleting dnsmasq configuration file..."
		rm /etc/dnsmasq.conf
		echo -en "[OK]\n"

		echo ""
		echo -en "Purging iw, batctl, bridge-utils, hostapd and dnsmasq..."
		# how do i uninstall with apt-get
		apt-get purge -y bridge-utils hostapd dnsmasq batctl iw
		apt-get autoremove
		echo -en "[OK]\n"

		# restore the previous interfaces file
		echo -en "Restoring previous network interfaces configuration file..."
		rm /etc/network/interfaces
		mv /etc/network/interfaces.bak /etc/network/interfaces
		echo -en "[OK]\n"

		# restore the previous /etc/dhcpcd.conf file
		echo -en "Restoring previous dhcpcd configuration file..."
		rm /etc/dhcpcd.conf
		mv /etc/dhcpcd.conf.bak /etc/dhcpcd.conf
		echo -en "[OK]\n"

		# Remove startup scripts and delete
		echo -en "Disabling and deleting startup meshpi startup scripts..."
		update-rc.d -f meshpi_mesh remove
		rm /etc/init.d/meshpi_mesh
		update-rc.d -f meshpi_ap remove
		rm /etc/init.d/meshpi_ap

		# Remove meshpi config file
		echo -en "Deleting /etc/meshpi.config..."
		rm /etc/meshpi.config

		echo "Deleting meshpi folder"
		cd "$(dirname "$(pwd)")"
		rm -rf meshpi
		echo -en "[OK]\n"
		read -p "Do you wish to reboot now? [N] " yn
		case $yn in
			[Yy]* )
				reboot;;
			[Nn]* ) exit 0;;
		esac

	;;
	[Nn]* ) exit 0;;
esac

exit 0
