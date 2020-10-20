#!/bin/bash

# Upgrade all the things
apt update
apt upgrade -y
apt dist-upgrade -y
apt autoremove -y