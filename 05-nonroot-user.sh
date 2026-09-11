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
userhome=$(getent passwd "$NONROOT_USERNAME" | cut -d: -f6)
usergroup=$(id -gn "$NONROOT_USERNAME")

# Migrate the old shared snippet without losing another user's restriction.
legacy_deny=/etc/ssh/sshd_config.d/15-vps-setup-deny-users.conf
if sudo test -f "$legacy_deny"; then
	legacy_user=$(sudo awk '$1 == "DenyUsers" && NF == 2 { print $2 }' "$legacy_deny")
	if [[ "$legacy_user" =~ ^[a-z_][a-z0-9_-]{0,31}$ && "$legacy_user" != users ]]; then
		sudo mv "$legacy_deny" "/etc/ssh/sshd_config.d/15-vps-setup-deny-$legacy_user.conf"
	fi
fi

# Deny user SSH access
if [ "$NONROOT_SSH" = "n" ]; then
	echo "DenyUsers $NONROOT_USERNAME" | sudo tee "$SSH_DENY_CONFIG" >/dev/null
	reload_ssh_access
else
	# add the ssh key to this user as well
	sudo rm -f "$SSH_DENY_CONFIG"
	sudo install -d -m 700 -o "$NONROOT_USERNAME" -g "$usergroup" "$userhome/.ssh"
	# Preserve keys already installed for this user.
	keys="$userhome/.ssh/authorized_keys"
	sudo touch "$keys"
	if sudo test -s "$keys" && [ -n "$(sudo tail -c 1 "$keys")" ]; then
		printf '\n' | sudo tee -a "$keys" >/dev/null
	fi
	while IFS= read -r public_key || [ -n "$public_key" ]; do
		if [ -n "$public_key" ] && ! sudo grep -qxF "$public_key" "$keys"; then
			printf '%s\n' "$public_key" | sudo tee -a "$keys" >/dev/null
		fi
	done <"$SCRIPT_DIR/key.pub"
	sudo chown "$NONROOT_USERNAME:$usergroup" "$keys"
	sudo chmod 600 "$keys"
	reload_ssh_access
fi

echo "Nonroot user created"
