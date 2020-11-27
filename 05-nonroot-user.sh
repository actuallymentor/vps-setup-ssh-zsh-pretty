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
ZSH="/home/$NONROOT_USERNAME/.oh-my-zsh" sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)" "" --unattended
mkdir -p /home/$NONROOT_USERNAME/.oh-my-zsh/custom/themes/
curl -o /home/$NONROOT_USERNAME/.oh-my-zsh/custom/themes/agnoster-newline.zsh-theme https://gist.githubusercontent.com/nweddle/e456229c0a773c32d37b/raw/b4fef3b4a113677e47ab08cc98bd8cbc71d1a4dc/agnoster-newline.zsh-theme
echo '
ZSH_THEME="agnoster-newline"
plugins=(git)
source $ZSH/oh-my-zsh.sh
' >> /home/$NONROOT_USERNAME/.zshrc

# Deny user SSH access
echo "DenyUsers $username" >> /etc/ssh/sshd_config