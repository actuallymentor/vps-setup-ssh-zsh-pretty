#!/bin/bash
set -euo pipefail

# Set default SSH_PORT to 22
SSH_PORT=${SSH_PORT:-22}
SCRIPT_DIR="${SCRIPT_DIR:-$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)}"
SSH_CONFIG="/etc/ssh/sshd_config.d/10-vps-setup.conf"
SSH_SOCKET_CONFIG="/etc/systemd/system/ssh.socket.d/10-vps-setup.conf"
AUTHORIZED_KEYS="$HOME/.ssh/authorized_keys"

echo "Configuring sshd"

reloadSSH() {
	sudo install -d -m 755 /run/sshd
	sudo sshd -t

	if sudo systemctl is-enabled --quiet ssh.socket 2>/dev/null || sudo systemctl is-active --quiet ssh.socket 2>/dev/null; then
		sudo install -d -m 755 /etc/systemd/system/ssh.socket.d
		{
			echo "[Socket]"
			echo "ListenStream="
			echo "ListenStream=0.0.0.0:$SSH_PORT"
			echo "ListenStream=[::]:$SSH_PORT"
		} | sudo tee "$SSH_SOCKET_CONFIG" >/dev/null

		sudo systemctl daemon-reload
		sudo systemctl enable ssh.socket
		sudo systemctl restart ssh.socket

		# If ssh.service is already active, reload it so config changes such as
		# DenyUsers and stale listeners are not left to the next connection.
		sudo systemctl reload ssh.service 2>/dev/null || true
	else
		sudo systemctl reload ssh.service || sudo systemctl restart ssh.service
	fi
}

if [ ! -f "$SCRIPT_DIR/key.pub" ]; then
	echo "Missing $SCRIPT_DIR/key.pub"
	exit 1
fi

# SSH Setup
install -d -m 700 "$HOME/.ssh"
touch "$AUTHORIZED_KEYS"
chmod 600 "$AUTHORIZED_KEYS"

while IFS= read -r public_key || [ -n "$public_key" ]; do
	if [ -n "$public_key" ] && ! grep -qxF "$public_key" "$AUTHORIZED_KEYS"; then
		printf '%s\n' "$public_key" >>"$AUTHORIZED_KEYS"
	fi
done <"$SCRIPT_DIR/key.pub"

# Ubuntu includes sshd_config.d snippets before the main file; most sshd
# directives use the first value found, so an early snippet wins cleanly.
sudo install -d -m 755 /etc/ssh/sshd_config.d
{
	echo "# Managed by vps-setup-ssh-zsh-pretty"
	echo "Port $SSH_PORT"
	echo "AuthorizedKeysFile .ssh/authorized_keys .ssh/authorized_keys2"
	echo "PasswordAuthentication no"
	echo "KbdInteractiveAuthentication no"
	echo "PermitRootLogin prohibit-password"
} | sudo tee "$SSH_CONFIG" >/dev/null

reloadSSH

echo "ssh configured and restarted"
