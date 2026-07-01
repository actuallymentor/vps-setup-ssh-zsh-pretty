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

reload_ssh_access() {
	sudo install -d -m 755 /run/sshd
	sudo sshd -t

	if sudo systemctl is-enabled --quiet ssh.socket 2>/dev/null || sudo systemctl is-active --quiet ssh.socket 2>/dev/null; then
		sudo systemctl daemon-reload
		sudo systemctl restart ssh.socket
		sudo systemctl reload ssh.service 2>/dev/null || true
	else
		sudo systemctl reload ssh.service || sudo systemctl restart ssh.service
	fi
}

# Check if $NONROOT_USERNAME user already exists
if id "$NONROOT_USERNAME" &>/dev/null; then
	echo "User $NONROOT_USERNAME already exists, skipping"
else
	# Create new user with sudo privileges
	sudo adduser --disabled-password --gecos "" "$NONROOT_USERNAME"
	sudo usermod -aG sudo "$NONROOT_USERNAME"

	if [ -z "${NONROOT_PASSWORD:-}" ]; then
		echo "NONROOT_PASSWORD is required for a new nonroot user"
		exit 1
	fi

	printf '%s:%s\n' "$NONROOT_USERNAME" "$NONROOT_PASSWORD" | sudo chpasswd
fi

# Set zsh as default shell
sudo chsh -s "$(command -v zsh)" "$NONROOT_USERNAME"

# Oh my zsh for subuser
installOhMyZSH "$NONROOT_USERNAME"
userhome=$(getent passwd "$NONROOT_USERNAME" | cut -d: -f6)
sudo chown -R "$NONROOT_USERNAME:$NONROOT_USERNAME" "$userhome"

# Deny user SSH access
if [ "$NONROOT_SSH" = "n" ]; then
	echo "DenyUsers $NONROOT_USERNAME" | sudo tee /etc/ssh/sshd_config.d/15-vps-setup-deny-users.conf >/dev/null
	reload_ssh_access
else
	# add the ssh key to this user as well
	sudo rm -f /etc/ssh/sshd_config.d/15-vps-setup-deny-users.conf
	sudo install -d -m 700 -o "$NONROOT_USERNAME" -g "$NONROOT_USERNAME" "$userhome/.ssh"
	sudo install -m 600 -o "$NONROOT_USERNAME" -g "$NONROOT_USERNAME" "$HOME/.ssh/authorized_keys" "$userhome/.ssh/authorized_keys"
	reload_ssh_access
fi

echo "Nonroot user created"
