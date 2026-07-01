# vps-setup-ssh-zsh-pretty

Setup script to set up Ubuntu 26.04 LTS VPS servers the way I like them.

I advise adding your own SSH key into the script. Use this verbatim and you'll be giving me control of your servers.

Usage:

```bash
git clone https://github.com/actuallymentor/vps-setup-ssh-zsh-pretty.git setup && cd setup
# CHANGE THE key.pub FILE TO YOUR KEY
bash setup.sh
cd .. && rm -rf ./setup
```

To run this script silently (skips firewall and nonroot user), pass `true` as the first argument:

```
bash setup.sh true
```

## Important notes:

1. This script targets Ubuntu 26.04 LTS.
1. This will disable password-based authentication on your system, make sure you have an ssh key installed or you will not be able to SSH into your server **at all**.
	- An implicit assumption is that you run this script from a user that logs in via an ssh key.
	- When using a custom SSH port, verify the listener with `sudo ss -tlnp | grep sshd` before closing your current session.
1. Automatic reboot after unattended upgrades defaults to `true`.
1. Swap setup intentionally disables existing swap and leaves the machine with only `/swapfile` configured by this script.
1. Docker is installed from Docker's Ubuntu apt repository for the detected Ubuntu codename.
1. Docker-published ports are not automatically protected by UFW; bind containers deliberately or add Docker firewall rules before exposing services.
