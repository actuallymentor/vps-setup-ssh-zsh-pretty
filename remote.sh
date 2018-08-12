#!/bin/bash

echo "Server ip/address?"
read serverip
echo "List of .ssh:"
ls ~/.ssh
echo "public ssh key path? (full path)"
read sshkey

# Copy setup script
echo "Uploading scripts"
scp ./shell.sh ./ssh.sh ./upgrade.sh root@$serverip:~
echo "Uploading ssh keys"
cat "$sshkey" | ssh root@$serverip "mkdir -p ~/.ssh && cat >>  ~/.ssh/authorized_keys"
echo "Running scripts"
ssh root@$serverip "bash ~/ssh.sh && bash shell.sh"