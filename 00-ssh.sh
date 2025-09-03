
#!/bin/bash
set -e

# Set default SSH_PORT to 22
SSH_PORT=${SSH_PORT:-22}

echo "Configuring sshd"

# Enable the port in the settings
sudo sed -i "s/#\{0,1\}Port 22/Port $SSH_PORT/g" /etc/ssh/sshd_config
sudo systemctl restart ssh

# SSH Setup
mkdir -p ~/.ssh
chmod 700 ~/.ssh
touch ~/.ssh/authorized_keys
chmod 600 ~/.ssh/authorized_keys
cat ./key.pub >> ~/.ssh/authorized_keys
sudo sed -i 's/#\{0,1\}AuthorizedKeysFile/AuthorizedKeysFile/g' /etc/ssh/sshd_config
sudo sed -i 's/ChallengeResponseAuthentication yes/ChallengeResponseAuthentication no/g' /etc/ssh/sshd_config

# Disable passworded login
sudo sed -i 's/#\{0,1\}PasswordAuthentication yes/PasswordAuthentication no/g' /etc/ssh/sshd_config

# Disable root login with password
sudo sed -i 's/#\{0,1\}PermitRootLogin yes/PermitRootLogin prohibit-password/g' /etc/ssh/sshd_config
sudo service ssh reload

echo "ssh configured and restarted"