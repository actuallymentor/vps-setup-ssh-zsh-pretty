# Size of physical RAM plus 1
ramsize=$(echo $((1 + $(getconf _PHYS_PAGES) * $(getconf PAGE_SIZE) / (1024 * 1024 * 1024))))
unit=G

# Alocate swap space
sudo fallocate -l "$ramsize$unit" /swapfile

# Set permissions
sudo chmod 600 /swapfile

# Enable swap on the /swapfile path
sudo mkswap /swapfile
sudo swapon /swapfile
sudo swapon --show

# Permanence after reboot
sudo cp /etc/fstab /etc/fstab.bak
echo '/swapfile none swap sw 0 0' | sudo tee -a /etc/fstab
