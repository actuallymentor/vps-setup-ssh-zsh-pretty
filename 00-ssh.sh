#!/bin/bash

echo "Configuring sshd"

# Enable the port in the settings
sed -i "s/#\{0,1\}Port 22/Port $SSH_PORT/g" /etc/ssh/sshd_config
systemctl restart ssh

# SSH Setup
mkdir -p ~/.ssh
chmod 700 ~/.ssh
touch ~/.ssh/authorized_keys
chmod 600 ~/.ssh/authorized_keys
cat ./key.pub >> ~/.ssh/authorized_keys
sed -i 's/#\{0,1\}AuthorizedKeysFile/AuthorizedKeysFile/g' /etc/ssh/sshd_config
sed -i 's/ChallengeResponseAuthentication yes/ChallengeResponseAuthentication no/g' /etc/ssh/sshd_config

# Disable passworded login
sed -i 's/#\{0,1\}PasswordAuthentication yes/PasswordAuthentication no/g' /etc/ssh/sshd_config

# Disable root login with password
sed -i 's/#\{0,1\}PermitRootLogin yes/PermitRootLogin prohibit-password/g' /etc/ssh/sshd_config
service ssh reload

echo "ssh configured and restarted"