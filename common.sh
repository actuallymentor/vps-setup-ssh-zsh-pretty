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
