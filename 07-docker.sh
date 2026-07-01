#!/bin/bash
set -euo pipefail

apt_get() {
	if [ "${NONINTERACTIVE:-y}" = "y" ]; then
		sudo env DEBIAN_FRONTEND=noninteractive apt-get -o DPkg::Lock::Timeout=600 "$@"
	else
		sudo apt-get -o DPkg::Lock::Timeout=600 "$@"
	fi
}

configure_docker_access() {
	local current_user

	current_user=${SUDO_USER:-${USER:-$(id -un)}}
	echo -e "\nAdding user $current_user to docker group\n"
	sudo groupadd docker &>/dev/null || true
	sudo usermod -aG docker "$current_user"

	if [ -n "${NONROOT_USERNAME:-}" ]; then
		echo -e "\nAdding nonroot user $NONROOT_USERNAME to docker group\n"
		sudo usermod -aG docker "$NONROOT_USERNAME"
	fi
}

# Exit if docker is installed
if command -v docker >/dev/null 2>&1; then
	echo "Docker is already installed"
	docker --version
	echo "If you suspect that docker is not installed correctly, you can run the following command to uninstall it:"
	echo -e "apt-get purge -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin\n"
	configure_docker_access

	if [[ "${BASH_SOURCE[0]}" != "$0" ]]; then
		return 0
	fi

	exit 0
fi

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
for package in docker.io docker-compose docker-compose-v2 docker-doc podman-docker; do
	apt_get remove -y "$package" || true
done

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
