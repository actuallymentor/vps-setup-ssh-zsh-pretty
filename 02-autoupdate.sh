#!/bin/bash

echo "Configuring auto update"

# Automatic updates
apt install unattended-upgrades update-notifier-common -y
echo -e "
APT::Periodic::Update-Package-Lists \"1\";
APT::Periodic::Unattended-Upgrade \"1\";
APT::Periodic::AutocleanInterval \"7\";
Unattended-Upgrade::Remove-Unused-Dependencies \"true\";
Unattended-Upgrade::Remove-New-Unused-Dependencies \"true\";
Unattended-Upgrade::Automatic-Reboot \"$AUTO_REBOOT_AT_UPGRADE\";
Unattended-Upgrade::Automatic-Reboot-Time \"02:00\";
" > /etc/apt/apt.conf.d/20auto-upgrades
service unattended-upgrades restart

echo "Auto update configured"