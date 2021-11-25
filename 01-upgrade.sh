#!/bin/bash

echo "Running package upgrade"

# Update repos
sudo apt-get update

# Check if we are clear to install
if sudo apt-get install --simulate apt; then
	echo "Starting update process"
	sudo apt-get install -y apt
else
	echo "Nother process is installing through apt-get, exiting"
	exit 1
fi


# Upgrade all the things
if sudo apt-get upgrade --simulate; then
	sudo apt update
	sudo apt upgrade -y
	sudo apt dist-upgrade -y
	sudo apt autoremove -y
else
	echo "Nother process is installing through apt-get, exiting"
	exit 1
fi

echo "Package upgrade done"