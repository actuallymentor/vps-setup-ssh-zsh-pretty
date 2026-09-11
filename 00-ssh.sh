#!/bin/bash
set -euo pipefail

# Set default SSH_PORT to 22
SSH_PORT=${SSH_PORT:-22}
SCRIPT_DIR="${SCRIPT_DIR:-$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)}"
SSH_CONFIG="/etc/ssh/sshd_config.d/10-vps-setup.conf"
SSH_SOCKET_CONFIG="/etc/systemd/system/ssh.socket.d/10-vps-setup.conf"
AUTHORIZED_KEYS="$HOME/.ssh/authorized_keys"
# shellcheck source=common.sh
source "$SCRIPT_DIR/common.sh"
validate_ssh_port
validate_ssh_key

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
		# Restart both units together so sshd receives the new listening sockets.
		# Ubuntu's KillMode=process preserves established SSH sessions.
		sudo systemctl restart ssh.socket ssh.service
	else
		# A reload can retain inherited sockets after switching activation modes.
		sudo systemctl restart ssh.service
	fi
}

previous_ssh_port=""

# Allow reconnection before moving the listener on an already firewalled host.
if command -v ufw >/dev/null && sudo ufw status | grep -q '^Status: active'; then
	if sudo test -f "$SSH_CONFIG"; then
		previous_ssh_port=$(sudo awk '$1 == "Port" { print $2; exit }' "$SSH_CONFIG")
	fi

	# UFW treats an opposite-action rule as an existing match for insert.
	sudo ufw --force delete deny "$SSH_PORT/tcp"
	sudo ufw insert 1 allow "$SSH_PORT/tcp" comment 'Allow ssh on custom port'
fi

# SSH Setup
install -d -m 700 "$HOME/.ssh"
touch "$AUTHORIZED_KEYS"
chmod 600 "$AUTHORIZED_KEYS"

# Separate an existing final line that has no newline before appending keys.
if [ -s "$AUTHORIZED_KEYS" ] && [ -n "$(tail -c 1 "$AUTHORIZED_KEYS")" ]; then
	printf '\n' >>"$AUTHORIZED_KEYS"
fi

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

# Retire the previous managed SSH allowance after the new listener is ready.
if [[ "$previous_ssh_port" =~ ^[0-9]{1,5}$ && "$previous_ssh_port" != "$SSH_PORT" ]]; then
	sudo ufw --force delete allow "$previous_ssh_port/tcp"
fi

echo "ssh configured and restarted"
