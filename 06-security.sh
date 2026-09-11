#!/bin/bash
set -euo pipefail

echo "Configuring security measures"

# Firewall default is incoming
FIREWALL=${FIREWALL:-incoming}
SSH_PORT=${SSH_PORT:-22}
PROC_HIDE_GROUP=${PROC_HIDE_GROUP:-sudo}

# shellcheck source=common.sh
source "$(dirname -- "${BASH_SOURCE[0]}")/common.sh"

#########################
# Timekeeping: Use chrony, migrate from ntp if present
# https://chrony.tuxfamily.org/
#########################

# Remove ntp if installed and migrate to chrony
if dpkg-query -W -f='${db:Status-Abbrev}' ntp 2>/dev/null | grep -q '^ii'; then
	echo "Migrating from ntp to chrony..."
	sudo systemctl stop ntp || true
	apt_get remove --purge -y ntp
	apt_get autoremove -y
fi

# Install chrony
apt_get update
apt_get install -y chrony

# Backup chrony config (only if it exists)
if [ -f /etc/chrony/chrony.conf ]; then
	sudo cp --archive /etc/chrony/chrony.conf "/etc/chrony/chrony.conf-COPY-$(date +"%Y%m%d%H%M%S")"
fi

# Enable and restart chrony
sudo systemctl enable chrony
sudo systemctl restart chrony
echo "Timekeeping configured with chrony"

###################################
# Secure /proc process information
# https://github.com/imthenachoman/How-To-Secure-A-Linux-Server#securing-proc
###################################

sudo cp --archive /etc/fstab "/etc/fstab-COPY-$(date +"%Y%m%d%H%M%S")"

proc_gid=$(getent group "$PROC_HIDE_GROUP" | cut -d: -f3 || true)
if [ -z "$proc_gid" ]; then
	echo "Could not find $PROC_HIDE_GROUP group for /proc hidepid whitelist"
	exit 1
fi

tmp_fstab=$(mktemp)
awk '
	$0 ~ /^[[:space:]]*#/ { print; next }
	NF == 0 { print; next }
	$1 == "proc" && $2 == "/proc" && $3 == "proc" { next }
	{ print }
' /etc/fstab >"$tmp_fstab"
echo "proc /proc proc defaults,hidepid=2,gid=$proc_gid 0 0 # vps-setup-managed proc" >>"$tmp_fstab"
sudo install -m 644 "$tmp_fstab" /etc/fstab
rm -f "$tmp_fstab"
sudo systemctl daemon-reload

# Remount unless the live mount already has the managed hidepid settings.
if ! mount | grep -E '^proc on /proc ' | grep -Eq 'hidepid=(2|invisible)' || ! mount | grep -E '^proc on /proc ' | grep -q "gid=$proc_gid"; then
	sudo mount -o "remount,hidepid=2,gid=$proc_gid" /proc
else
	echo "/proc already mounted with hidepid=2,gid=$proc_gid, skipping remount."
fi

################################
# Autoban failed attempts & DDOS
# https://github.com/imthenachoman/How-To-Secure-A-Linux-Server#application-intrusion-detection-and-prevention-with-fail2ban
################################
apt_get install -y fail2ban mosh

#########################
# Firewall
# https://github.com/imthenachoman/How-To-Secure-A-Linux-Server#firewall-with-ufw-uncomplicated-firewall
#########################
if [ "$FIREWALL" != "n" ]; then
	apt_get install -y ufw

	# Bidirectional mode allows only the outbound services used by this suite.
	if [ "$FIREWALL" = "bidirectional" ]; then
		# Disallow by default
		sudo ufw default deny outgoing comment 'deny all outgoing traffic'
		sudo ufw default deny incoming comment 'deny all incoming traffic'
		# Allow specific things
		sudo ufw allow out 53 comment 'allow DNS calls out'
		# DHCP renewal uses UDP sockets even when initial discovery bypasses UFW.
		sudo ufw allow out proto udp from any port 68 to any port 67 comment 'Allow DHCPv4 client'
		sudo ufw allow out proto udp from any port 546 to any port 547 comment 'Allow DHCPv6 client'
		sudo ufw allow out 123/udp comment 'allow NTP out'
		sudo ufw allow out 4460/tcp comment 'allow NTS key exchange out'
		sudo ufw allow out http comment 'allow HTTP traffic out'   # apt is likely to use these
		sudo ufw allow out https comment 'allow HTTPS traffic out' # apt is likely to use these
		# Mosh can resume after conntrack expires or the client changes networks.
		sudo ufw allow out proto udp from any port 60000:61000 to any comment 'Allow Mosh replies'
	fi

	# If the firewall is set to incoming, block incoming only
	if [ "$FIREWALL" = "incoming" ]; then
		# Disallow by default
		echo "Setting UFW to deny incoming connections by default"
		sudo ufw default deny incoming comment 'deny all incoming traffic'
		sudo ufw default allow outgoing comment 'allow all outgoing traffic'
	fi

	# Remove the old suite rule before allowing port 22 again.
	sudo ufw --force delete deny 22/tcp

	if [ "$SSH_PORT" != "22" ]; then
		echo "Denying default SSH port 22/tcp"
		sudo ufw --force delete allow 22/tcp
		sudo ufw prepend deny 22/tcp comment 'Deny default SSH port'
	fi

	# Allow ssh access
	echo "Allowing SSH on port $SSH_PORT/tcp"
	sudo ufw --force delete deny "$SSH_PORT/tcp"
	sudo ufw prepend allow "$SSH_PORT/tcp" comment 'Allow ssh on custom port'
	sudo ufw allow 60000:61000/udp comment 'Allow Mosh'

	# Enable and log
	sudo ufw status numbered
	echo -e "\nUFW will now enable. SSH uses TCP $SSH_PORT; Mosh uses UDP 60000:61000."
	echo -e "You can log back in using the -p $SSH_PORT flag in your command"
	if [ "${NONINTERACTIVE:-y}" != "y" ]; then
		read -r -n 1 -p "Press any key to continue" _
		echo
	fi

	sudo ufw --force enable

fi

{
	echo "[sshd]"
	echo "enabled = true"
	if [ "$FIREWALL" != "n" ]; then
		echo "banaction = ufw"
	fi
	echo "backend = systemd"
	echo "port = $SSH_PORT"
	echo "filter = sshd"
	echo "maxretry = 5"
} | sudo tee /etc/fail2ban/jail.d/ssh.conf >/dev/null

sudo systemctl enable fail2ban.service
sudo systemctl restart fail2ban.service

echo "Security config complete"
