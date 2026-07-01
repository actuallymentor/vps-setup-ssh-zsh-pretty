#!/bin/bash
set -euo pipefail

THEME_URL="https://gist.githubusercontent.com/nweddle/e456229c0a773c32d37b/raw/b4fef3b4a113677e47ab08cc98bd8cbc71d1a4dc/agnoster-newline.zsh-theme"

apt_get() {
	if [ "${NONINTERACTIVE:-y}" = "y" ]; then
		sudo env DEBIAN_FRONTEND=noninteractive apt-get -o DPkg::Lock::Timeout=600 "$@"
	else
		sudo apt-get -o DPkg::Lock::Timeout=600 "$@"
	fi
}

# Install zsh and dependencies used by this script
apt_get install -y zsh git curl
sudo usermod -s "$(command -v zsh)" "$(id -un)"

# Recyclable zsh install function for use here and in the nonroot user section
function installOhMyZSH() {
	local username=$1
	local userhome
	local zsh_dir
	local zshrc

	userhome=$(getent passwd "$username" | cut -d: -f6)
	if [ -z "$userhome" ]; then
		echo "Could not find home directory for $username"
		exit 1
	fi

	zsh_dir="$userhome/.oh-my-zsh"
	zshrc="$userhome/.zshrc"
	echo "Installing Oh My ZSH as $username in $zsh_dir"

	# Backup old zshrc once unless it is already managed by this setup.
	if [ -f "$zshrc" ] && ! sudo grep -q "Managed by vps-setup-ssh-zsh-pretty" "$zshrc"; then
		sudo mv "$zshrc" "$zshrc.bak.$(date +"%Y%m%d%H%M%S")"
	fi

	if [ ! -d "$zsh_dir/.git" ]; then
		echo "Starting oh my zsh install"
		sudo rm -rf "$zsh_dir"
		sudo -u "$username" git clone --depth=1 https://github.com/ohmyzsh/ohmyzsh.git "$zsh_dir"
	else
		echo "Oh My ZSH already installed"
	fi

	echo "Creating custom theme folder"
	sudo install -d -o "$username" -g "$username" "$zsh_dir/custom/themes"
	sudo -u "$username" curl -fSL -o "$zsh_dir/custom/themes/agnoster-newline.zsh-theme" "$THEME_URL"

	echo "Creating ~/.zshrc"
	sudo tee "$zshrc" >/dev/null <<EOF
# Managed by vps-setup-ssh-zsh-pretty
export ZSH="$zsh_dir"
ZSH_THEME="agnoster-newline"
plugins=(git)
source "$zsh_dir/oh-my-zsh.sh"
EOF

	sudo chown "$username:$username" "$zshrc"
	sudo chown -R "$username:$username" "$zsh_dir"
	echo "ZSH installation done"

}

# Install for current user
installOhMyZSH "$(id -un)"
