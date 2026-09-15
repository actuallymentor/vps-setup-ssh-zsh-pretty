#!/bin/bash
set -euo pipefail

# shellcheck source=common.sh
source "$(dirname -- "${BASH_SOURCE[0]}")/common.sh"

configure_docker_access() {
	local current_user

	current_user=$(setup_user)
	echo -e "\nAdding user $current_user to docker group\n"
	sudo groupadd docker &>/dev/null || true
	sudo usermod -aG docker "$current_user"

	if [ -n "${NONROOT_USERNAME:-}" ]; then
		echo -e "\nAdding nonroot user $NONROOT_USERNAME to docker group\n"
		sudo usermod -aG docker "$NONROOT_USERNAME"
	fi
}

# As per https://docs.docker.com/engine/install/ubuntu/#set-up-the-repository

if [ -f /etc/os-release ]; then
	# shellcheck disable=SC1091
	. /etc/os-release
else
	echo "/etc/os-release is missing; cannot configure Docker repository"
	exit 1
fi

if [ "${ID:-}" != "ubuntu" ]; then
	echo "This Docker installer is intended for Ubuntu hosts, not ${ID:-unknown}"
	exit 1
fi

DOCKER_SUITE="${UBUNTU_CODENAME:-${VERSION_CODENAME:-}}"
if [ -z "$DOCKER_SUITE" ]; then
	echo "Could not determine Ubuntu codename for Docker repository"
	exit 1
fi

DOCKER_ARCH="$(dpkg --print-architecture)"

# Remove conflicting distro packages before installing Docker CE.
conflicts=()
for package in docker.io docker-compose docker-compose-v2 docker-doc docker-buildx podman-docker containerd runc; do
	if dpkg-query -W -f='${db:Status-Abbrev}' "$package" 2>/dev/null | grep -q '^ii'; then
		conflicts+=("$package")
	fi
done
if [ "${#conflicts[@]}" -gt 0 ]; then
	apt_get remove -y "${conflicts[@]}"
fi

# Set up repository
echo -e "\n\nSetting up dependencies to install docker repository keys\n\n"
apt_get update
apt_get install -y ca-certificates curl

echo -e "\n\nSetting up docker repository keys\n\n"
sudo install -m 0755 -d /etc/apt/keyrings
sudo curl -fsSL https://download.docker.com/linux/ubuntu/gpg -o /etc/apt/keyrings/docker.asc
sudo chmod a+r /etc/apt/keyrings/docker.asc
sudo rm -f /etc/apt/sources.list.d/docker.list
sudo tee /etc/apt/sources.list.d/docker.sources >/dev/null <<EOF
Types: deb
URIs: https://download.docker.com/linux/ubuntu
Suites: $DOCKER_SUITE
Components: stable
Architectures: $DOCKER_ARCH
Signed-By: /etc/apt/keyrings/docker.asc
EOF

# Install
echo -e "\n\nInstalling docker\n\n"
apt_get update
apt_get install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin

configure_docker_access

echo -e "\nStarting docker daemon\n"
sudo systemctl enable --now docker.service
sudo docker version
sudo docker compose version
sudo docker buildx version
