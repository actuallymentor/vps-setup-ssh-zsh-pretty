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