Mesh Pi
========

Fork from [subnodes](https://github.com/chootka/subnodes).

Goal is to get a layer 2 mesh with a [Libre Mesh](https://libremesh.org) router using a [Raspberry Pi](https://www.raspberrypi.org/) [v3](https://www.raspberrypi.org/products/raspberry-pi-3-model-b/) or [Zero W](https://www.raspberrypi.org/products/raspberry-pi-zero-w/) the easiest way possible.

## Usage

For this to work it is assumed that you are running a Raspberry Pi 3 or Pi Zero W with an additional mesh compatible usb dongle such as [TP-LINK_TL-WN722N](https://wikidevi.com/wiki/TP-LINK_TL-WN722N) v1 or v1.2, not [v2](https://wikidevi.com/wiki/TP-LINK_TL-WN722N_v2). The access point will be set up utilizing the Pi's internal wireless radio.

Make sure you have the additional radio and an ethernet cable connecting the Pi to the internet. On the first boot it will take a little bit to get first steps ready for you. You can check what's hapenning using `ps -ef`. Once the Pi reboots, it's all ready. Let's get in:

`ssh pi@meshpi` with the password `meshpi`

There you'll find the folder `meshpi`. You'll need to set the configuration files. 

`vim meshpi.config`

It's set for Libre Mesh settings, but the USB device `phy` address may vary.
 
 Use `iw phy  | grep phy` to list your devices and `iw phy phyX info` to find the device with `mesh-point` capability
 
 Check to other configurations and once you're ready run the install script:

`sudo ./install.sh`

The installation process takes about 15 minutes. After it has completed, you will have a running node.js web server, wireless access point, and BATMAN Advanced mesh node. Connecting to the network and navigating to a browser page will redirect you to http://www.subnodes.org, where a sample node.js chat client will be running. 

From here, fork, build, share your ideas, and have fun!

## Without the image

If you don't want to use the image, you can go through the steps manually assuming you're using a fresh Raspbian Lite install.

* set up your Raspberry Pi with a basic configuration

        sudo raspi-config

* update apt-get

        sudo apt-get update
        
* install git

        sudo apt-get install git

* clone the repository into your home folder (assuming /home/pi)

        git clone https://github.com/luandro/meshpi.git

* configure your wireless access point and mesh network in meshpi.config in any text editor, or in the command line you can use nano

        vim meshpi.config

* run the installation script

        cd meshpi
        sudo ./install.sh

## About Subnodes

Subnodes is an open source project that turns your Linux device running the latest Raspbian (as of this writing, Stretch Lite) into an offline mesh node and wireless access point.

This project is an initiative focused on streamlining the process of setting up a Raspberry Pi as a wireless access point for distributing content, media, and shared digital experiences. The device becomes a web server, creating its own local area network, and does not connect with the internet. This is key for the sake of offering a space where people can communicate anonymously and freely, as well as maximizing the portability of the network (no dependibility on an internet connection means the device can be taken and remain active anywhere). 

The device can also be configured as a BATMAN Advanced mesh node, enabling it to join with other nearby BATMAN nodes into a greater mesh network, extending the access point range and making it possible to exchange information with each other. Support for meshpi has been provided by Eyebeam. This code is published under the [AGPLv3](http://www.gnu.org/licenses/agpl-3.0.html).

## References

* [Subnodes website](http://www.subnodes.org/)
* [Raspberry Pi](http://www.raspberrypi.org/)
* [eyebeam](http://eyebeam.org/)
