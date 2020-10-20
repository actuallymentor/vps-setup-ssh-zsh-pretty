#!/bin/bash

# Change SSH port to custom
echo "Processes currently using your configured SSH port ($SSH_PORT)"
ss -tulpn | grep $SSH_PORT
sed -i "s/#Port 22/Port $SSH_PORT/g" /etc/ssh/sshd_config # If commented original line is there
sed -i "s/^Port 22/Port $SSH_PORT/g" /etc/ssh/sshd_config # If there is an active uncommented line
ufw allow "$SSH_PORT/tcp" comment 'Allow custom SSH port'
ufw deny 22/tcp comment 'Deny default SSH port'
systemctl restart ssh

# SSH Setup
mkdir -p ~/.ssh
cat ./key.pub >> ~/.ssh/authorized_keys
sed -i 's/#AuthorizedKeysFile/AuthorizedKeysFile/g' /etc/ssh/sshd_config
sed -i 's/PermitRootLogin yes/PermitRootLogin without-password/g' /etc/ssh/sshd_config
service sshd reload