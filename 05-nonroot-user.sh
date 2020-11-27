################
# User setup
################

# Create new user with sudo privileges
adduser --gecos "" $NONROOT_USERNAME
usermod -aG sudo $NONROOT_USERNAME
echo "$NONROOT_USERNAME:$NONROOT_PASSWORD" | chpasswd

# Set zsh as default shell
chsh -s `which zsh` $NONROOT_USERNAME

# Oh my zsh for subuser
ZSH=/home/$NONROOT_USERNAME/.oh-my-zsh installOhMyZSH /home/$NONROOT_USERNAME

# Deny user SSH access
echo "DenyUsers $username" >> /etc/ssh/sshd_config