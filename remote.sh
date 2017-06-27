#!/bin/bash

echo "Server ip?"
read serverip
echo "ssh key loaction?"
read sshkey

# Copy setup script
scp ./shell.sh root@$serverip:~
scp ./ssh.sh root@$serverip:~
scp ./upgrade.sh root@$serverip:~

cat ~/.ssh/sshkey | ssh root@$serverip "mkdir -p ~/.ssh && cat >>  ~/.ssh/authorized_keys"
ssh root@$serverip "bash ~/ssh.sh && bash shell.sh"