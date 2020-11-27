#!/bin/bash

sudo apt-get update
sudo apt-get install -y apt

# Upgrade all the things
sudo apt update
sudo apt upgrade -y
sudo apt dist-upgrade -y
sudo apt autoremove -y
