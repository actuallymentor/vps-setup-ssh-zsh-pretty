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
sudo timedatectl set-ntp no
timedatectl

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
port = ssh
filter = sshd
logpath = %(sshd_log)s
maxretry = 5
" > /etc/fail2ban/jail.d/ssh.local

#########################
# Firewall
# https://github.com/imthenachoman/How-To-Secure-A-Linux-Server#firewall-with-ufw-uncomplicated-firewall
#########################
sudo apt install -y ufw

# Disallow by default
sudo ufw default deny outgoing comment 'deny all outgoing traffic'
sudo ufw default deny incoming comment 'deny all incoming traffic'

# Allow specific things
sudo ufw allow "$SSH_PORT/tcp" comment 'Allow ssh on custom port'
sudo ufw allow out 53 comment 'allow DNS calls out'
sudo ufw allow out 123 comment 'allow NTP out' # For timekeeping, see below
sudo ufw allow out http comment 'allow HTTP traffic out' # apt is likely to use these
sudo ufw allow out https comment 'allow HTTPS traffic out' # apt is likely to use these

# Enable and log
sudo ufw enable
sudo ufw status numbered