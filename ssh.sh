#!/bin/bash
#  Set up ssh
mkdir -p ~/.ssh
sudo sudo sed -i 's/#AuthorizedKeysFile/AuthorizedKeysFile/g' /etc/ssh/sshd_config
sudo sed -i 's/PermitRootLogin yes/PermitRootLogin without-password/g' /etc/ssh/sshd_config
sudo service ssh restart