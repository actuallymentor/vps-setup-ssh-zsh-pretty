#!/bin/bash
set -euo pipefail

swaploc=/swapfile
timestamp=$(date +"%Y%m%d%H%M%S")

rewrite_fstab() {
	local tmp_fstab

	tmp_fstab=$(mktemp)

	# Intentionally remove all swap entries so this suite owns the final swap
	# configuration. For /tmp, remove only the mountpoint we are replacing.
	awk '
		$0 ~ /^[[:space:]]*#/ { print; next }
		NF == 0 { print; next }
		$3 == "swap" { next }
		$2 == "/tmp" { next }
		{ print }
	' /etc/fstab >"$tmp_fstab"

	{
		printf '%s none swap sw 0 0 # vps-setup-managed swap\n' "$swaploc"
		printf 'tmpfs /tmp tmpfs defaults,noatime,nosuid,nodev,mode=1777,size=%sM 0 0 # vps-setup-managed tmpfs\n' "$tmpfs_size"
	} >>"$tmp_fstab"

	sudo install -m 644 "$tmp_fstab" /etc/fstab
	rm -f "$tmp_fstab"
}

# Size of physical RAM plus 1
ramsize=$((1 + $(getconf _PHYS_PAGES) * $(getconf PAGE_SIZE) / (1024 * 1024 * 1024)))
unit=G

# Disable swap in case it is in use
sudo swapoff -a

# Allocate swap space
sudo rm -f "$swaploc"
if ! sudo fallocate -l "$ramsize$unit" "$swaploc"; then
	sudo dd if=/dev/zero of="$swaploc" bs=1M count=$((ramsize * 1024)) status=progress
fi

# Set permissions
sudo chmod 600 "$swaploc"

# Enable swap on the $swaploc path
sudo mkswap -f "$swaploc"
sudo swapon "$swaploc"
sudo swapon --show

# Set swappiness to be lower
sudo tee /etc/sysctl.d/99-vps-setup-swap.conf >/dev/null <<'EOF'
vm.swappiness=6
vm.vfs_cache_pressure=10
EOF
sudo sysctl -p /etc/sysctl.d/99-vps-setup-swap.conf

# Permanence after reboot
sudo cp --archive /etc/fstab "/etc/fstab-COPY-$timestamp"

# Make tmpfs with half the RAM size
tmpfs_size=$(($(getconf _PHYS_PAGES) * $(getconf PAGE_SIZE) / (1024 * 1024) / 2))
rewrite_fstab

# Create /tmp directory if it does not exist
sudo mkdir -p /tmp

# Reload generated mount units after editing fstab.
sudo systemctl daemon-reload
sudo mount -a
sudo mount -o remount /tmp
