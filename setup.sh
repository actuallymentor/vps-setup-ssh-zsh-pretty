#!/bin/bash

SILENT_INSTALL=$1

# Check if a silent install was requested
if [[ -v SILENT_INSTALL ]]; then
	echo "Silent install requested, using defaults"
else
	# Settings
	echo "Do you want to automatically reboot after an auto-upgrade? [true/false]"
	read AUTO_REBOOT_AT_UPGRADE

	echo "What SSH port do you want to configure? (default 22)"
	read SSH_PORT

	echo "What username should the non root sudo user have?"
	read NONROOT_USERNAME

	echo "What password should this user have?"
	read -s NONROOT_PASSWORD

	echo "Should the nonroot user be able to SSH into the machine? [y/n] (default y)"
	read NONROOT_SSH

	echo "Should I set up a restrictive firewall? [y/n] (default n)"
	read FIREWALL

fi

# Set defaults
AUTO_REBOOT_AT_UPGRADE=${AUTO_REBOOT_AT_UPGRADE:-true}
NONROOT_USERNAME=${NONROOT_USERNAME:-toor}
NONROOT_SSH=${NONROOT_SSH:-y}
SSH_PORT=${SSH_PORT:-22}
FIREWALL=${FIREWALL:-n}

# Exit if error
set -e

# Fix common networking error
sudo echo "127.0.0.1 $(hostname)" >> /etc/hosts

## SSH key
source ./00-ssh.sh

## Upgrade full system
source ./01-upgrade.sh

## Enable autoupdates with purging
source ./02-autoupdate.sh

## Install and configure ZSH
source ./03-zsh.sh

## Add swap space (1 + size of ram)
source ./04-swap.sh

if [[ -v SILENT_INSTALL ]]; then
	echo "Silent install does NOT create nonroot user"
else
	## Add a nonroot user
	source ./05-nonroot-user.sh
fi

## Add basic security measures
source ./06-security.sh
