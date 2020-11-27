#!/bin/bash

# Enable the port in the settings
sed -i "s/#Port 22/Port $SSH_PORT/g" /etc/ssh/sshd_config # If commented original line is there
sed -i "s/^Port 22/Port $SSH_PORT/g" /etc/ssh/sshd_config # If there is an active uncommented line
systemctl restart ssh

# SSH Setup
mkdir -p ~/.ssh
cat ./key.pub >> ~/.ssh/authorized_keys
sed -i 's/#AuthorizedKeysFile/AuthorizedKeysFile/g' /etc/ssh/sshd_config
sed -i 's/PermitRootLogin yes/PermitRootLogin without-password/g' /etc/ssh/sshd_config
service sshd reload
