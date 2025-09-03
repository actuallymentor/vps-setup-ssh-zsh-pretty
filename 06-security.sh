#!/bin/bash 
set -e

echo "Configuring security measures"

# Firewall default is incoming
FIREWALL=${FIREWALL:-incoming}


#########################
# Timekeeping: Use chrony, migrate from ntp if present
# https://chrony.tuxfamily.org/
#########################

# Remove ntp if installed and migrate to chrony
if dpkg -l | grep -qw ntp; then
	echo "Migrating from ntp to chrony..."
	sudo systemctl stop ntp || true
	sudo apt-get remove --purge -y ntp
	sudo apt-get autoremove -y
fi

# Install chrony
sudo apt-get update
sudo apt-get install -y chrony


# Backup chrony config (only if it exists)
if [ -f /etc/chrony/chrony.conf ]; then
	sudo cp --archive /etc/chrony/chrony.conf /etc/chrony/chrony.conf-COPY-$(date +"%Y%m%d%H%M%S")
fi

# Enable and restart chrony
sudo systemctl enable chrony
sudo systemctl restart chrony
sudo systemctl status chrony
chronyc sources

###################################
# Secure /proc process information
# https://github.com/imthenachoman/How-To-Secure-A-Linux-Server#securing-proc
###################################

sudo cp --archive /etc/fstab /etc/fstab-COPY-$(date +"%Y%m%d%H%M%S")
# Only add /proc line if not already present with hidepid=2
if ! grep -E '^proc\s+/proc\s+proc' /etc/fstab | grep -q 'hidepid=2'; then
	echo -e "\nproc     /proc     proc     defaults,hidepid=2     0     0         # added by $(whoami) on $(date +"%Y-%m-%d @ %H:%M:%S")" | sudo tee -a /etc/fstab
else
	echo "/proc hidepid=2 already set in /etc/fstab, skipping duplicate."
fi
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
sudo apt install -y fail2ban
echo -e "
[sshd]
enabled = true
banaction = ufw
port = $SSH_PORT
filter = sshd
logpath = %(sshd_log)s
maxretry = 5
" | sudo tee /etc/fail2ban/jail.d/ssh.conf

#########################
# Firewall
# https://github.com/imthenachoman/How-To-Secure-A-Linux-Server#firewall-with-ufw-uncomplicated-firewall
#########################
if [ "$FIREWALL" != "n" ]; then
	
	sudo apt install -y ufw

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
		sudo ufw default deny incoming comment 'deny all incoming traffic'
	fi

	# This is default behaviour, adding for verbosity
	if [ "$SSH_PORT" != "22" ]; then
		sudo ufw deny 22/tcp comment 'Deny default SSH port'
	fi

	# Allow ssh access
	sudo ufw allow "$SSH_PORT/tcp" comment 'Allow ssh on custom port'
	

	# Enable and log
	sudo ufw status numbered
	echo -e "\nUFW will now enable, your current tunnel will break because your SSH port is now $SSH_PORT"
	echo -e "You can log back in using the -p $SSH_PORT flag in your command"
	echo -e "Press any key to continue"
	read

	sudo ufw --force enable

fi

echo "Security config complete"