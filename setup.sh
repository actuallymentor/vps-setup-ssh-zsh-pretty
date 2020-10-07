#!/bin/bash

# Exit if error
set -e

## SSH key
bash ./00-ssh.sh

## Upgrade full system
bash ./01-upgrade.sh

## Enable autoupdates with purging
bash ./02-autoupdate.sh

## Install and configure ZSH
bash ./03-zsh.sh

## Add swap space (1 + size of ram)
bash ./04-swap.sh

# Reboot because of all the updates
reboot