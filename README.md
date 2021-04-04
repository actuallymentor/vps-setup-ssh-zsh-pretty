# vps-setup-ssh-zsh-pretty

Setup script to set up VPS servers the way I like them.

I advise adding your own SSH key into the script. Use this verbatim and you'll be giving me control of your servers.

Usage:

```bash
git clone https://github.com/actuallymentor/vps-setup-ssh-zsh-pretty.git setup && cd setup
# CHANGE THE key.pub FILE TO YOUR KEY
bash setup.sh
cd .. && rm -rf ./setup
```

## Important notes:

1. This script assumes default config files for `sshd` and `unattended-upgrades`
1. This will disable password-based authentication on your system, make sure you have an ssh key installed or you will not be able to SSH into your server **at all**
	- An implicit assumption is that you run this script from a root user that logs in via an ssh key
