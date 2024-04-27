#!/bin/bash

SILENT_INSTALL=$1

# Check if a silent install was requested
if [ "$SILENT_INSTALL" ]; then
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

	echo "Should I set up a firewall? [incoming/bidirectional/n] (default n)"
	read FIREWALL


fi

# Set defaults
AUTO_REBOOT_AT_UPGRADE=${AUTO_REBOOT_AT_UPGRADE:-true}
NONROOT_USERNAME=${NONROOT_USERNAME:-toor}
NONROOT_SSH=${NONROOT_SSH:-y}
SSH_PORT=${SSH_PORT:-22}
FIREWALL=${FIREWALL:-n}

# validate that all inputs are correct
if [ "$AUTO_REBOOT_AT_UPGRADE" != "true" ] && [ "$AUTO_REBOOT_AT_UPGRADE" != "false" ]; then
	echo "AUTO_REBOOT_AT_UPGRADE must be true or false"
	exit 1
fi

# Check if the non-route, SSH user should be able to SSH into the machine
if [ "$NONROOT_SSH" != "y" ] && [ "$NONROOT_SSH" != "n" ]; then
	echo "NONROOT_SSH must be y or n"
	exit 1
fi

# Check if the firewall settings are correct
if [ "$FIREWALL" != "incoming" ] && [ "$FIREWALL" != "bidirectional" ] && [ "$FIREWALL" != "n" ]; then
	echo "FIREWALL must be incoming, bidirectional, or n"
	exit 1
fi

# Check if the SSH port is a numberq
if ! [[ "$SSH_PORT" =~ ^[0-9]+$ ]]; then
	echo "SSH_PORT must be a number"
	exit 1
fi

# Check if the SSH port is between 1 and 65535
if [ "$SSH_PORT" -lt 1 ] || [ "$SSH_PORT" -gt 65535 ]; then
	echo "SSH_PORT must be between 1 and 65535"
	exit 1
fi

if [ ! "$SILENT_INSTALL" ]; then
	# Check if the nonroot user is alphanumeric
	if ! [[ "$NONROOT_USERNAME" =~ ^[a-zA-Z0-9]+$ ]]; then
		echo "NONROOT_USERNAME must be alphanumeric"
		exit 1
	fi

	# Check if the nonroot password is valid
	if [ ${#NONROOT_PASSWORD} -lt 8 ]; then
		echo "NONROOT_PASSWORD must be at least 8 characters"
		exit 1
	fi
fi



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

if [ "$SILENT_INSTALL" ]; then
	echo "Silent install does NOT create nonroot user"
else
	## Add a nonroot user
	source ./05-nonroot-user.sh
fi

## Add basic security measures
source ./06-security.sh
