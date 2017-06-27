sudo apt-get update
sudo apt-get upgrade -y

# Set up terminal
sudo apt-get install zsh -y
wget https://github.com/robbyrussell/oh-my-zsh/raw/master/tools/install.sh -O - | zsh
chsh -s `which zsh`
mkdir -p ~/.oh-my-zsh/custom/themes/
curl -o ~/.oh-my-zsh/custom/themes/agnoster-newline.zsh-theme https://gist.githubusercontent.com/nweddle/e456229c0a773c32d37b/raw/b4fef3b4a113677e47ab08cc98bd8cbc71d1a4dc/agnoster-newline.zsh-theme
echo '
ZSH_THEME="agnoster-newline"
plugins=(git)
source $ZSH/oh-my-zsh.sh
' >> ~/.zshrc

#  Set up ssh
mkdir -p ~/.ssh
echo 'AAAAB3NzaC1yc2EAAAADAQABAAABAQDQIPEEZTyUasFtiMWEpW0da1FuhK1ZSQLBSRdy4S
6Mm4WEDA9Xu2rRISbpwnEQ4Y/js6dUtVOlubz0KtNKyWyiuoD0ugwAOZ3y29mtGUlLIJ00
cNa1XdVQEUVYe+EB8NwI3pp8Pn0L2UX/RmsB7nMvBMhx/JsSoMiyz8BChVR4CppSsU3Zao
QbQ/p3X43ZfBYxVdM0WXiekGQDqNa4/eUYk2sxTydQ3eyXF4v990tk4dJUjCwTkXYkYuBD
zhkz89+JAQMJ3o1HPV1NHyUD7nCkIzQp7GH5hzYws7NVQTjhrDY+BO8ZWRo5uu8noWVuUc
+fHznkpufkeWDG+m3BD/BR' >> ~/.ssh/authorized_keys
sudo sudo sed -i 's/#AuthorizedKeysFile/AuthorizedKeysFile/g' /etc/ssh/sshd_config
sudo sed -i 's/PermitRootLogin yes/PermitRootLogin without-password/g' /etc/ssh/sshd_config
sudo service ssh restart

sudo reboot