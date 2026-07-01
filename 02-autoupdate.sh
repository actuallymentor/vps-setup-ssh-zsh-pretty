#!/bin/bash
set -euo pipefail

# Auto reboot defaults to true by design for this setup suite.
AUTO_REBOOT_AT_UPGRADE=${AUTO_REBOOT_AT_UPGRADE:-true}

echo "Configuring auto update"

apt_get() {
	if [ "${NONINTERACTIVE:-y}" = "y" ]; then
		sudo env DEBIAN_FRONTEND=noninteractive apt-get -o DPkg::Lock::Timeout=600 "$@"
	else
		sudo apt-get -o DPkg::Lock::Timeout=600 "$@"
	fi
}

# Automatic updates
apt_get install -y unattended-upgrades update-notifier-common

sudo tee /etc/apt/apt.conf.d/20auto-upgrades >/dev/null <<'EOF'
APT::Periodic::Update-Package-Lists "1";
APT::Periodic::Unattended-Upgrade "1";
APT::Periodic::AutocleanInterval "7";
EOF

sudo tee /etc/apt/apt.conf.d/52-vps-setup-unattended-upgrades >/dev/null <<EOF
Unattended-Upgrade::Remove-Unused-Dependencies "true";
Unattended-Upgrade::Remove-New-Unused-Dependencies "true";
Unattended-Upgrade::Automatic-Reboot "$AUTO_REBOOT_AT_UPGRADE";
Unattended-Upgrade::Automatic-Reboot-Time "02:00";
EOF

sudo systemctl restart unattended-upgrades.service

echo "Auto update configured"
