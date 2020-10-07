# Size of physical RAm plus 1
ramsize=$(echo $((1 + $(getconf _PHYS_PAGES) * $(getconf PAGE_SIZE) / (1024 * 1024 * 1024))))
unit=G

# sudo fallocate -l 1G /swapfile
sudo fallocate -l "$ramsize$unit" /swapfile

sudo chmod 600 /swapfile
ls -lh /swapfile

sudo mkswap /swapfile
sudo swapon /swapfile
sudo swapon --show

# PERMANENCE
sudo cp /etc/fstab /etc/fstab.bak
echo '/swapfile none swap sw 0 0' | sudo tee -a /etc/fstab