# vps-setup-ssh-zsh-pretty

Setup script to set up VPS servers the way I like them.

I advice adding your own SSH key into the script. Use this verbatim and you'll be giving me control of your servers.

## Usage

To add an ssh key, update the server and set up zsh with the agnoster theme run ```shell bash ./remote.sh``` fron your local machine. The script will connect to the server based on details it will ask for.

You may also separately run ``` bash ./shell.sh``` on the remote machine to make the terminal pretty.