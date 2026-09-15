#!/bin/bash
set -euo pipefail
################
# User setup
################

echo "Creating nonroot user"

if [ -z "${NONROOT_USERNAME:-}" ]; then
	echo "NONROOT_USERNAME is empty, skipping nonroot user setup"
	if [[ "${BASH_SOURCE[0]}" != "$0" ]]; then
		return 0
	fi

	exit 0
fi

if ! declare -F installOhMyZSH >/dev/null; then
	echo "installOhMyZSH must be loaded before running this script"
	exit 1
fi

# Access changes do not alter listening sockets.
reload_ssh_access() {
	sudo install -d -m 755 /run/sshd
	sudo /usr/sbin/sshd -t
	sudo systemctl reload ssh.service || sudo systemctl restart ssh.service
}

NONROOT_SSH=${NONROOT_SSH:-y}
SSH_DENY_CONFIG="/etc/ssh/sshd_config.d/15-vps-setup-deny-$NONROOT_USERNAME.conf"

# Check if $NONROOT_USERNAME user already exists
if id "$NONROOT_USERNAME" &>/dev/null; then
	echo "User $NONROOT_USERNAME already exists, preserving password"
else
	if [ -z "${NONROOT_PASSWORD:-}" ]; then
		echo "NONROOT_PASSWORD is required for a new nonroot user"
		exit 1
	fi

	sudo adduser --disabled-password --gecos "" "$NONROOT_USERNAME"
	printf '%s:%s\n' "$NONROOT_USERNAME" "$NONROOT_PASSWORD" | sudo chpasswd
fi

sudo usermod -aG sudo "$NONROOT_USERNAME"

# Set zsh as default shell
sudo chsh -s "$(command -v zsh)" "$NONROOT_USERNAME"

# Oh my zsh for subuser
installOhMyZSH "$NONROOT_USERNAME"

migrate_ssh_deny

# Deny user SSH access
if [ "$NONROOT_SSH" = "n" ]; then
	echo "DenyUsers $NONROOT_USERNAME" | sudo tee "$SSH_DENY_CONFIG" >/dev/null
	reload_ssh_access
else
	# add the ssh key to this user as well
	sudo rm -f "$SSH_DENY_CONFIG"
	install_ssh_key "$NONROOT_USERNAME"
	reload_ssh_access
fi

echo "Nonroot user created"
