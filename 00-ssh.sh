#!/bin/bash
set -euo pipefail

# Set default SSH_PORT to 22
SSH_PORT=${SSH_PORT:-22}
SCRIPT_DIR="${SCRIPT_DIR:-$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)}"
SSH_CONFIG="/etc/ssh/sshd_config.d/10-vps-setup.conf"
AUTHORIZED_KEYS="$HOME/.ssh/authorized_keys"

echo "Configuring sshd"

if [ ! -f "$SCRIPT_DIR/key.pub" ]; then
	echo "Missing $SCRIPT_DIR/key.pub"
	exit 1
fi

# SSH Setup
install -d -m 700 "$HOME/.ssh"
touch "$AUTHORIZED_KEYS"
chmod 600 "$AUTHORIZED_KEYS"

while IFS= read -r public_key; do
	if [ -n "$public_key" ] && ! grep -qxF "$public_key" "$AUTHORIZED_KEYS"; then
		printf '%s\n' "$public_key" >>"$AUTHORIZED_KEYS"
	fi
done <"$SCRIPT_DIR/key.pub"

# Ubuntu includes sshd_config.d snippets before the main file; most sshd
# directives use the first value found, so an early snippet wins cleanly.
sudo install -d -m 755 /etc/ssh/sshd_config.d
sudo install -d -m 755 /run/sshd
{
	echo "# Managed by vps-setup-ssh-zsh-pretty"
	echo "Port $SSH_PORT"
	echo "AuthorizedKeysFile .ssh/authorized_keys .ssh/authorized_keys2"
	echo "PasswordAuthentication no"
	echo "KbdInteractiveAuthentication no"
	echo "PermitRootLogin prohibit-password"
} | sudo tee "$SSH_CONFIG" >/dev/null

sudo sshd -t
sudo systemctl reload ssh.service || sudo systemctl restart ssh.service

echo "ssh configured and restarted"
