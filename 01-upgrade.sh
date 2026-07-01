#!/bin/bash
set -euo pipefail

echo "Running package upgrade"

apt_get() {
	if [ "${NONINTERACTIVE:-y}" = "y" ]; then
		sudo env DEBIAN_FRONTEND=noninteractive apt-get -o DPkg::Lock::Timeout=600 "$@"
	else
		sudo apt-get -o DPkg::Lock::Timeout=600 "$@"
	fi
}

# Update repos
apt_get update

echo "Starting update process"
apt_get install -y apt

apt_get upgrade -y
apt_get dist-upgrade -y
apt_get autoremove -y

echo "Package upgrade done"
