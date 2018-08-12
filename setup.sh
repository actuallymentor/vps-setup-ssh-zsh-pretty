#!/bin/bash

# Exit if error
set -e

# SSH Setup
mkdir -p ~/.ssh
cat ./key.pub >> ~/.ssh/authorized_keys
sed -i 's/#AuthorizedKeysFile/AuthorizedKeysFile/g' /etc/ssh/sshd_config
sed -i 's/PermitRootLogin yes/PermitRootLogin without-password/g' /etc/ssh/sshd_config
service sshd reload

# Update repos
apt update

# Install zsh and highlighting
apt install zsh -y
wget https://raw.githubusercontent.com/robbyrussell/oh-my-zsh/master/tools/install.sh -O - | zsh
chsh -s `which zsh`
mkdir -p ~/.oh-my-zsh/custom/themes/
curl -o ~/.oh-my-zsh/custom/themes/agnoster-newline.zsh-theme https://gist.githubusercontent.com/nweddle/e456229c0a773c32d37b/raw/b4fef3b4a113677e47ab08cc98bd8cbc71d1a4dc/agnoster-newline.zsh-theme
echo '
ZSH_THEME="agnoster-newline"
plugins=(git)
source $ZSH/oh-my-zsh.sh
' >> ~/.zshrc

# Upgrade all the things
apt upgrade -y

# Automatic updates
apt install unattended-upgrades -y
echo -e '
APT::Periodic::Update-Package-Lists "1";
APT::Periodic::Unattended-Upgrade "1";
Unattended-Upgrade::Automatic-Reboot "true";
Unattended-Upgrade::Automatic-Reboot-Time "02:00";
' > /etc/apt/apt.conf.d/20auto-upgrades
service unattended-upgrades restart