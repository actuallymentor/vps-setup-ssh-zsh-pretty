#!/bin/bash

# Install zsh and highlighting
apt install zsh -y
chsh -s `which zsh`

# Recyclable zsh install function for use here and in the nonroot user section
function installOhMyZSH() {

	sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)" "" --unattended
	mkdir -p $ZSH/custom/themes/
	curl -o $ZSH/custom/themes/agnoster-newline.zsh-theme https://gist.githubusercontent.com/nweddle/e456229c0a773c32d37b/raw/b4fef3b4a113677e47ab08cc98bd8cbc71d1a4dc/agnoster-newline.zsh-theme
	echo '
	ZSH_THEME="agnoster-newline"
	plugins=(git)
	source $ZSH/oh-my-zsh.sh
	' >> $1/.zshrc

}

ZSH=~/.oh-my-zsh installOhMyZSH ~
