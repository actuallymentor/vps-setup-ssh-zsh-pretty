
#!/bin/bash
set -e

echo "Running package upgrade"

# Wait for package lock
while fuser /var/{lib/{dpkg,apt/lists},cache/apt/archives}/lock >/dev/null 2>&1; do
	echo "Another package script is running, waiting for it to exit..."
	sleep 10
done

# Update repos
sudo apt-get update

# Check if we are clear to install
if sudo apt-get install --simulate apt; then
	echo "Starting update process"
	sudo apt-get install -y apt
else
	echo "Nother process is installing through apt-get, exiting"
	exit 1
fi


# Upgrade all the things
if sudo apt-get upgrade --simulate; then
	if [[ -v SILENT_INSTALL ]]; then
		sudo DEBIAN_FRONTEND=noninteractive apt update
		sudo DEBIAN_FRONTEND=noninteractive apt upgrade -y
		sudo DEBIAN_FRONTEND=noninteractive apt dist-upgrade -y
		sudo DEBIAN_FRONTEND=noninteractive apt autoremove -y
	else
		sudo apt update
		sudo apt upgrade -y
		sudo apt dist-upgrade -y
		sudo apt autoremove -y
	fi
else
	echo "Nother process is installing through apt-get, exiting"
	exit 1
fi

echo "Package upgrade done"