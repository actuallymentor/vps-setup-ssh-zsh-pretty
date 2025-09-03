#!/bin/bash
set -e
################
# User setup
################

echo "Creating nonroot user"

# Check if $NONROOT_USERNAME user already exists
if id "$NONROOT_USERNAME" &>/dev/null; then
	echo "User $NONROOT_USERNAME already exists, skipping"
else
	# Create new user with sudo privileges
	sudo adduser --disabled-password --gecos "" $NONROOT_USERNAME
	sudo usermod -aG sudo $NONROOT_USERNAME
	echo "$NONROOT_USERNAME:$NONROOT_PASSWORD" | sudo chpasswd
fi

# Set zsh as default shell
sudo chsh -s `which zsh` $NONROOT_USERNAME

# Oh my zsh for subuser
installOhMyZSH $NONROOT_USERNAME
sudo chown -R $NONROOT_USERNAME $( eval echo "~$NONROOT_USERNAME" )

# Deny user SSH access
if [ "$NONROOT_SSH" = "n" ]; then
	echo "DenyUsers $NONROOT_USERNAME" >> /etc/ssh/sshd_config
else
	# add the ssh key to this user as well
	sudo mkdir -p /home/$NONROOT_USERNAME/.ssh
	sudo cp /root/.ssh/authorized_keys /home/$NONROOT_USERNAME/.ssh/authorized_keys
	sudo chown -R $NONROOT_USERNAME:$NONROOT_USERNAME /home/$NONROOT_USERNAME/.ssh
	sudo chmod 700 /home/$NONROOT_USERNAME/.ssh
	sudo chmod 600 /home/$NONROOT_USERNAME/.ssh/authorized_keys
fi

echo "Nonroot user created"