#!/bin/bash

echo "Server ip/address?"
read serverip
echo "User name?"
read username
echo "List og .ssh:"
ls ~/.ssh
echo "ssh key path?"
read sshkey

# Copy setup script
echo "Uploading scripts"
scp ./shell.sh ./ssh.sh ./upgrade.sh $username@$serverip:~
echo "Uploading ssh keys"
cat "$sshkey" | ssh $username@$serverip "mkdir -p ~/.ssh && cat >>  ~/.ssh/authorized_keys"
echo "Running scripts"
ssh $username@$serverip "bash ~/ssh.sh && bash shell.sh"