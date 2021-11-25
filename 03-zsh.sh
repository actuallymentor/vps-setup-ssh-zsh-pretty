#!/bin/bash

# Install zsh and highlighting
apt install zsh -y
chsh -s `which zsh`

# Recyclable zsh install function for use here and in the nonroot user section
function installOhMyZSH() {

	userhome=$( eval echo "~$1" )
	ZSH=$userhome/.oh-my-zsh
	echo "Installing Oh My ZSH as $1 in $ZSH"
	mv $userhome/.zshrc $userhome/.zshrc.bak || echo "no existing config"

	# install as current user or as suplied user
	echo "Starting oh my zsh install"
	sudo -u $1 sh -c "git clone https://github.com/ohmyzsh/ohmyzsh.git $ZSH"
	echo "Done installing oh my zsh"

	echo "Creating custom theme folder"
	mkdir -p $ZSH/custom/themes/
	curl -o $ZSH/custom/themes/agnoster-newline.zsh-theme https://gist.githubusercontent.com/nweddle/e456229c0a773c32d37b/raw/b4fef3b4a113677e47ab08cc98bd8cbc71d1a4dc/agnoster-newline.zsh-theme
	
	echo "Creating ~/.zshrc"
	echo -e "
	ZSH=$ZSH
	ZSH_THEME='agnoster-newline'
	plugins=(git)
	source $ZSH/oh-my-zsh.sh
	" > $userhome/.zshrc

	echo "ZSH installation done"

}

installOhMyZSH $(whoami)
