echo "Configuring security measures"

#########################
# Timekeeping
# https://github.com/imthenachoman/How-To-Secure-A-Linux-Server#ntp-client
#########################

# Install ntp and backup original settings
sudo apt install -y ntp
sudo cp --archive /etc/ntp.conf /etc/ntp.conf-COPY-$(date +"%Y%m%d%H%M%S")
# Enable pool and disable server
sudo sed -i -r -e "s/^((server|pool).*)/# \1         # commented by $(whoami) on $(date +"%Y-%m-%d @ %H:%M:%S")/" /etc/ntp.conf
echo -e "\npool pool.ntp.org iburst         # added by $(whoami) on $(date +"%Y-%m-%d @ %H:%M:%S")" | sudo tee -a /etc/ntp.conf

# Disable built in timekeeping
# https://www.digitalocean.com/community/tutorials/how-to-set-up-time-synchronization-on-ubuntu-20-04
sudo timedatectl set-ntp on || echo "Timedatectl disabled"

# Restart and statuses
sudo service ntp restart
sudo systemctl status ntp
sudo ntpq -p

###################################
# Secure /proc process information
# https://github.com/imthenachoman/How-To-Secure-A-Linux-Server#securing-proc
###################################

sudo cp --archive /etc/fstab /etc/fstab-COPY-$(date +"%Y%m%d%H%M%S")
echo -e "\nproc     /proc     proc     defaults,hidepid=2     0     0         # added by $(whoami) on $(date +"%Y-%m-%d @ %H:%M:%S")" | sudo tee -a /etc/fstab
sudo mount -o remount,hidepid=2 /proc

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
" > /etc/fail2ban/jail.d/ssh.local

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

	sudo ufw enable

fi

echo "Security config complete"