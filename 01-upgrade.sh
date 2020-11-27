#!/bin/bash

apt-get update
apt-get install -y apt

# Upgrade all the things
apt update
apt upgrade -y
apt dist-upgrade -y
apt autoremove -y
