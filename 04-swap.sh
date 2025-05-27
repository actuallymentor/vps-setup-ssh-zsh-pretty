# Size of physical RAM plus 1
swaploc=/swapfile
ramsize=$(echo $((1 + $(getconf _PHYS_PAGES) * $(getconf PAGE_SIZE) / (1024 * 1024 * 1024))))
unit=G

# Disable swap in case it is in use
sudo swapoff -a

# Alocate swap space
sudo fallocate -l "$ramsize$unit" $swaploc

# Set permissions
sudo chmod 600 $swaploc

# Enable swap on the $swaploc path
sudo mkswap $swaploc
sudo swapon $swaploc
sudo swapon --show

# Set swappiness to be lower
sudo sysctl vm.swappiness=6
sudo sysctl vm.vfs_cache_pressure=10
echo "vm.swappiness=6
vm.vfs_cache_pressure=10" | sudo tee -a /etc/sysctl.conf

# Permanence after reboot
sudo cp /etc/fstab /etc/fstab.bak
sudo sed -i '/swap/d' /etc/fstab
echo "$swaploc none swap sw 0 0" | sudo tee -a /etc/fstab

# Make /tmp use tmpfs
sudo cp /etc/fstab /etc/fstab.bak
sudo sed -i '/tmpfs/d' /etc/fstab

# Make tmpfs with half the RAM size
tmpfs_size=$(echo $(( $(getconf _PHYS_PAGES) * $(getconf PAGE_SIZE) / (1024 * 1024) / 2 )))
echo "tmpfs /tmp tmpfs defaults,noatime,nosuid,nodev,mode=1777,size=${tmpfs_size}M 0 0" | sudo tee -a /etc/fstab

# Create /tmp directory if it does not exist
sudo mkdir -p /tmp

# Mount all
sudo mount -a
