#!/bin/bash

# Keep package policy identical for the full suite and individual steps.
apt_get() {
	if [ "${NONINTERACTIVE:-y}" = "y" ]; then
		sudo env DEBIAN_FRONTEND=noninteractive NEEDRESTART_MODE=a apt-get \
			-o DPkg::Lock::Timeout=600 \
			-o Dpkg::Options::=--force-confdef \
			-o Dpkg::Options::=--force-confold "$@"
	else
		sudo env -u DEBIAN_FRONTEND -u NEEDRESTART_MODE apt-get -o DPkg::Lock::Timeout=600 "$@"
	fi
}

validate_ssh_port() {
	if ! [[ "$SSH_PORT" =~ ^[0-9]{1,5}$ ]] || ((10#$SSH_PORT < 1 || 10#$SSH_PORT > 65535)); then
		echo "SSH_PORT must be between 1 and 65535"
		exit 1
	fi

	SSH_PORT=$((10#$SSH_PORT))
}

validate_ssh_key() {
	if grep -q "PRIVATE KEY" "$SCRIPT_DIR/key.pub" 2>/dev/null ||
		! ssh-keygen -lf "$SCRIPT_DIR/key.pub" >/dev/null 2>&1; then
		echo "Put a valid SSH public key in $SCRIPT_DIR/key.pub before running setup"
		exit 1
	fi
}

# sudo preserves the login identity even when HOME points at /root.
setup_user() {
	if [ "$(id -u)" = 0 ] && [ -n "${SUDO_USER:-}" ] && [ "$SUDO_USER" != root ]; then
		printf '%s\n' "$SUDO_USER"
	else
		id -un
	fi
}

install_ssh_key() {
	local username=$1
	local userhome usergroup keys public_key

	userhome=$(getent passwd "$username" | cut -d: -f6)
	usergroup=$(id -gn "$username")
	[ -n "$userhome" ] || return 1
	keys="$userhome/.ssh/authorized_keys"

	sudo install -d -m 700 -o "$username" -g "$usergroup" "$userhome/.ssh"
	sudo touch "$keys"
	# Preserve existing keys, including a final line without a newline.
	if sudo test -s "$keys" && [ -n "$(sudo tail -c 1 "$keys")" ]; then
		printf '\n' | sudo tee -a "$keys" >/dev/null
	fi
	while IFS= read -r public_key || [ -n "$public_key" ]; do
		if [ -n "$public_key" ] && ! sudo grep -qxF "$public_key" "$keys"; then
			printf '%s\n' "$public_key" | sudo tee -a "$keys" >/dev/null
		fi
	done <"$SCRIPT_DIR/key.pub"
	sudo chown "$username:$usergroup" "$keys"
	sudo chmod 600 "$keys"
}

validate_nonroot_user() {
	[ -n "$NONROOT_USERNAME" ] || return 0

	if ! [[ "$NONROOT_USERNAME" =~ ^[a-z][a-z0-9_-]{0,31}$ ]]; then
		echo "NONROOT_USERNAME must be a valid Ubuntu username (up to 32 characters)"
		exit 1
	fi

	# Ubuntu regular accounts use UIDs 1000–60000; exclude nobody as well.
	local nonroot_uid
	nonroot_uid=$(id -u "$NONROOT_USERNAME" 2>/dev/null || true)
	if [ "$NONROOT_USERNAME" = "$(id -un)" ] || [ "$NONROOT_USERNAME" = "${SUDO_USER:-root}" ] ||
		{ [ -n "$nonroot_uid" ] && ((nonroot_uid < 1000 || nonroot_uid > 60000)); }; then
		echo "Choose a nonroot user other than the current login or a system account"
		exit 1
	fi

	if ! id "$NONROOT_USERNAME" &>/dev/null && [ ${#NONROOT_PASSWORD} -lt 8 ]; then
		echo "NONROOT_PASSWORD must be at least 8 characters for a new user"
		exit 1
	fi

	if [[ "$NONROOT_PASSWORD" == *$'\n'* || "$NONROOT_PASSWORD" == *$'\r'* ]]; then
		echo "NONROOT_PASSWORD must not contain newlines"
		exit 1
	fi
}
