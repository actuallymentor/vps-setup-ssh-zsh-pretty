#!/bin/bash
set -euo pipefail

SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=common.sh
source "$SCRIPT_DIR/common.sh"
SILENT_INSTALL=""
PROMPT_SETTINGS=y

case "${1:-}" in
"") ;;
true)
	SILENT_INSTALL=true
	PROMPT_SETTINGS=n
	;;
--noninteractive) PROMPT_SETTINGS=n ;;
--help | -h)
	echo "Usage: bash setup.sh [--noninteractive|true]"
	echo "--noninteractive: use environment settings without prompts"
	echo "true: legacy silent mode; skip firewall and nonroot user"
	exit 0
	;;
*)
	echo "Unknown argument: $1"
	exit 1
	;;
esac

if [ "$#" -gt 1 ]; then
	echo "Expected at most one argument"
	exit 1
fi

# Fail before touching SSH, packages, or mounts on unsupported hosts.
# shellcheck disable=SC1091
source /etc/os-release
if [ "$ID" != ubuntu ] || [[ "$VERSION_ID" != 24.04 && "$VERSION_ID" != 26.04 ]]; then
	echo "Supported systems: Ubuntu 24.04 and 26.04 LTS"
	exit 1
fi

validate_ssh_key

# Mounting tmpfs would hide the remaining scripts and break a run from /tmp.
if [[ "$SCRIPT_DIR" == /tmp || "$SCRIPT_DIR" == /tmp/* ]]; then
	echo "Run setup outside /tmp (for example, from your home directory)"
	exit 1
fi

AUTO_REBOOT_AT_UPGRADE=${AUTO_REBOOT_AT_UPGRADE:-}
SSH_PORT=${SSH_PORT:-}
NONROOT_USERNAME=${NONROOT_USERNAME:-}
NONROOT_PASSWORD=${NONROOT_PASSWORD:-}
NONROOT_SSH=${NONROOT_SSH:-}
FIREWALL=${FIREWALL:-}
NONINTERACTIVE=${NONINTERACTIVE:-}
SUDO_PID=""

cleanup() {
	if [ -n "$SUDO_PID" ] && kill -0 "$SUDO_PID" 2>/dev/null; then
		kill "$SUDO_PID"
		wait "$SUDO_PID" 2>/dev/null || true
	fi
}

trap cleanup EXIT

# Ask for settings unless unattended setup was requested.
if [ "$PROMPT_SETTINGS" = y ]; then
	# Settings
	echo "Do you want to automatically reboot after an auto-upgrade? [true/false] (default true)"
	read -r AUTO_REBOOT_AT_UPGRADE

	echo "What SSH port do you want to configure? (default 22)"
	read -r SSH_PORT

	echo "What username should the non root sudo user have? (empty for none)"
	read -r NONROOT_USERNAME

	if [ "$NONROOT_USERNAME" ]; then
		echo "What password should this user have?"
		read -rs NONROOT_PASSWORD
		echo

		echo "Should the nonroot user be able to SSH into the machine? [y/n] (default y)"
		read -r NONROOT_SSH
	fi

	echo "Should I set up a firewall? [incoming/bidirectional/n] (default incoming)"
	read -r FIREWALL

	echo "Should I install things noninteractively? [y/n] (default y)"
	read -r NONINTERACTIVE

fi

# Set defaults
AUTO_REBOOT_AT_UPGRADE=${AUTO_REBOOT_AT_UPGRADE:-true}
NONROOT_SSH=${NONROOT_SSH:-y}
SSH_PORT=${SSH_PORT:-22}
FIREWALL=${FIREWALL:-incoming}
NONINTERACTIVE=${NONINTERACTIVE:-y}

# validate that all inputs are correct
if [ "$AUTO_REBOOT_AT_UPGRADE" != "true" ] && [ "$AUTO_REBOOT_AT_UPGRADE" != "false" ]; then
	echo "AUTO_REBOOT_AT_UPGRADE must be true or false"
	exit 1
fi

# Check if the nonroot SSH user should be able to SSH into the machine
if [ "$NONROOT_SSH" != "y" ] && [ "$NONROOT_SSH" != "n" ]; then
	echo "NONROOT_SSH must be y or n"
	exit 1
fi

# Check if the firewall settings are correct
if [ "$FIREWALL" != "incoming" ] && [ "$FIREWALL" != "bidirectional" ] && [ "$FIREWALL" != "n" ]; then
	echo "FIREWALL must be incoming, bidirectional, or n"
	exit 1
fi

if [ "$NONINTERACTIVE" != "y" ] && [ "$NONINTERACTIVE" != "n" ]; then
	echo "NONINTERACTIVE must be y or n"
	exit 1
fi

validate_ssh_port

# Legacy silent mode intentionally skips user creation.
if [ "$SILENT_INSTALL" ]; then
	NONROOT_USERNAME=""
fi

validate_nonroot_user

if [ "$PROMPT_SETTINGS" = n ] && [ "$NONINTERACTIVE" != y ]; then
	echo "Unattended setup requires NONINTERACTIVE=y"
	exit 1
fi

# If SILENT_INSTALL, set firewall to n
if [ "$SILENT_INSTALL" ]; then
	echo "Silent install does NOT configure firewall"
	FIREWALL="n"
fi

# Fix common networking error
server_hostname="$(hostname)"
if ! grep -Fq "127.0.0.1 $server_hostname" /etc/hosts; then
	echo "127.0.0.1 $server_hostname" | sudo tee -a /etc/hosts >/dev/null
fi

# Activate sudo
sudo -v
(while true; do
	sudo -n true
	sleep 30
done) &
SUDO_PID=$!

## SSH key
source "$SCRIPT_DIR/00-ssh.sh"

## Upgrade full system
source "$SCRIPT_DIR/01-upgrade.sh"

## Enable autoupdates with purging
source "$SCRIPT_DIR/02-autoupdate.sh"

## Install and configure ZSH
source "$SCRIPT_DIR/03-zsh.sh"

## Add swap space (1 + size of ram)
source "$SCRIPT_DIR/04-swap.sh"

if [ "$SILENT_INSTALL" ]; then
	echo "Silent install does NOT create nonroot user"
else
	## Add a nonroot user if username set
	if [ "$NONROOT_USERNAME" ]; then
		source "$SCRIPT_DIR/05-nonroot-user.sh"
	fi
fi

## Add basic security measures
source "$SCRIPT_DIR/06-security.sh"

## Install docker
source "$SCRIPT_DIR/07-docker.sh"

echo "Setup complete (SSH TCP $SSH_PORT; Mosh UDP 60000:61000)"
