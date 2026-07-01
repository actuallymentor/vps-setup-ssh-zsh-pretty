#!/bin/bash
set -euo pipefail

echo "Configuring security measures"

# Firewall default is incoming
FIREWALL=${FIREWALL:-incoming}
SSH_PORT=${SSH_PORT:-22}

apt_get() {
	if [ "${NONINTERACTIVE:-y}" = "y" ]; then
		sudo env DEBIAN_FRONTEND=noninteractive apt-get -o DPkg::Lock::Timeout=600 "$@"
	else
		sudo apt-get -o DPkg::Lock::Timeout=600 "$@"
	fi
}

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

tmp_fstab=$(mktemp)
awk '
	$0 ~ /^[[:space:]]*#/ { print; next }
	NF == 0 { print; next }
	$1 == "proc" && $2 == "/proc" && $3 == "proc" { next }
	{ print }
' /etc/fstab >"$tmp_fstab"
echo "proc /proc proc defaults,hidepid=2 0 0 # vps-setup-managed proc" >>"$tmp_fstab"
sudo install -m 644 "$tmp_fstab" /etc/fstab
rm -f "$tmp_fstab"

# Remount only if not already set
if ! mount | grep -E '^proc on /proc ' | grep -q 'hidepid=2'; then
	sudo mount -o remount,hidepid=2 /proc
else
	echo "/proc already mounted with hidepid=2, skipping remount."
fi

################################
# Autoban failed attempts & DDOS
# https://github.com/imthenachoman/How-To-Secure-A-Linux-Server#application-intrusion-detection-and-prevention-with-fail2ban
################################
apt_get install -y fail2ban

#########################
# Firewall
# https://github.com/imthenachoman/How-To-Secure-A-Linux-Server#firewall-with-ufw-uncomplicated-firewall
#########################
if [ "$FIREWALL" != "n" ]; then
	apt_get install -y ufw

	# If the firewall is set to buy directional block outgoing and incoming
	if [ "$FIREWALL" = "bidirectional" ]; then
		# Disallow by default
		sudo ufw default deny outgoing comment 'deny all outgoing traffic'
		sudo ufw default deny incoming comment 'deny all incoming traffic' 
		# Allow specific things
		sudo ufw allow out 53 comment 'allow DNS calls out'
		sudo ufw allow out 123 comment 'allow NTP out' # For timekeeping, see below
		sudo ufw allow out http comment 'allow HTTP traffic out' # apt is likely to use these
		sudo ufw allow out https comment 'allow HTTPS traffic out' # apt is likely to use these
	fi

	# If the firewall is set to incoming, block incoming only
	if [ "$FIREWALL" = "incoming" ]; then
		# Disallow by default
		echo "Setting UFW to deny incoming connections by default"
		sudo ufw default deny incoming comment 'deny all incoming traffic'
	fi

	# This is default behaviour, adding for verbosity
	if [ "$SSH_PORT" != "22" ]; then
		echo "Denying default SSH port 22/tcp"
		sudo ufw deny 22/tcp comment 'Deny default SSH port'
	fi

	# Allow ssh access
	echo "Allowing SSH on port $SSH_PORT/tcp"
	sudo ufw allow "$SSH_PORT/tcp" comment 'Allow ssh on custom port'
	

	# Enable and log
	sudo ufw status numbered
	echo -e "\nUFW will now enable, your current tunnel will break because your SSH port is now $SSH_PORT"
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
	echo "port = $SSH_PORT"
	echo "filter = sshd"
	echo "logpath = %(sshd_log)s"
	echo "maxretry = 5"
} | sudo tee /etc/fail2ban/jail.d/ssh.conf >/dev/null

sudo systemctl enable fail2ban.service
sudo systemctl restart fail2ban.service

echo "Security config complete"
