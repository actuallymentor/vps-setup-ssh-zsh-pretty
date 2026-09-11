#!/bin/bash
# Run on a configured VPS as root: SSH_PORT=2222 FIREWALL=incoming bash tests/verify.sh
set -euo pipefail

SSH_PORT=${SSH_PORT:-22}
FIREWALL=${FIREWALL:-n}
AUTO_REBOOT_AT_UPGRADE=${AUTO_REBOOT_AT_UPGRADE:-true}

check() {
	local description=$1
	shift
	if ! "$@"; then
		printf 'FAIL %s\n' "$description" >&2
		return 1
	fi
	printf 'PASS %s\n' "$description"
}

check 'sshd configuration' /usr/sbin/sshd -t
ssh_config=$(/usr/sbin/sshd -T)
check 'SSH port' grep -qx "port $SSH_PORT" <<<"$ssh_config"
check 'SSH password authentication disabled' grep -qx 'passwordauthentication no' <<<"$ssh_config"
check 'SSH keyboard authentication disabled' grep -qx 'kbdinteractiveauthentication no' <<<"$ssh_config"
check 'SSH key-only root login' grep -Eq '^permitrootlogin (without-password|prohibit-password)$' <<<"$ssh_config"
check 'SSH listener' test -n "$(ss -H -ltn "sport = :$SSH_PORT")"

for service in ssh chrony fail2ban docker unattended-upgrades; do
	check "$service active" systemctl is-active --quiet "$service.service"
done
for service in chrony fail2ban docker; do
	check "$service enabled" systemctl is-enabled --quiet "$service.service"
done
check 'fail2ban SSH jail' fail2ban-client status sshd

check 'fstab valid' findmnt --verify --verbose
check 'single swap entry' test "$(awk '$1 !~ /^#/ && $3 == "swap" { n++ } END { print n+0 }' /etc/fstab)" = 1
check 'single active swapfile' test "$(swapon --noheadings --show=NAME)" = /swapfile
check 'swap permissions' test "$(stat -c %a /swapfile)" = 600
check 'tmpfs mounted' test "$(findmnt -n -o FSTYPE /tmp)" = tmpfs
check 'tmp permissions' test "$(stat -c %a /tmp)" = 1777
check 'proc privacy' grep -Eq 'hidepid=(2|invisible)' <<<"$(findmnt -n -o OPTIONS /proc)"
check 'swappiness' test "$(sysctl -n vm.swappiness)" = 6

apt_config=$(apt-config dump)
check 'automatic upgrades' grep -q 'APT::Periodic::Unattended-Upgrade "1";' <<<"$apt_config"
check 'automatic reboot setting' grep -q "Unattended-Upgrade::Automatic-Reboot \"$AUTO_REBOOT_AT_UPGRADE\";" <<<"$apt_config"
check 'automatic upgrade timer' systemctl is-enabled --quiet apt-daily-upgrade.timer
# shellcheck disable=SC2016 # Expanded by the child zsh.
check 'zsh startup' env DISABLE_AUTO_UPDATE=true zsh -ic '[[ -n "$ZSH" && "$ZSH_THEME" == agnoster-newline ]]'
check 'Mosh server' mosh-server --version

if [ "$FIREWALL" != n ]; then
	firewall_status=$(ufw status verbose)
	check 'firewall active' grep -q '^Status: active' <<<"$firewall_status"
	check 'Mosh UDP firewall rule' grep -Eq '60000:61000/udp[[:space:]]+ALLOW IN' <<<"$firewall_status"
	check 'SSH firewall rule' grep -Eq "^$SSH_PORT/tcp[[:space:]]+ALLOW IN" <<<"$firewall_status"
	if [ "$FIREWALL" = bidirectional ]; then
		check 'outgoing denied' grep -q 'deny (outgoing)' <<<"$firewall_status"
		check 'Mosh replies allowed' grep -Eq 'ALLOW OUT[[:space:]]+60000:61000/udp' <<<"$firewall_status"
		check 'NTS allowed' grep -Eq '4460/tcp[[:space:]]+ALLOW OUT' <<<"$firewall_status"
	else
		check 'outgoing allowed' grep -q 'allow (outgoing)' <<<"$firewall_status"
	fi
fi

if [ -n "${NONROOT_USERNAME:-}" ]; then
	check 'nonroot sudo membership' grep -qw sudo <<<"$(id -nG "$NONROOT_USERNAME")"
	check 'nonroot Docker membership' grep -qw docker <<<"$(id -nG "$NONROOT_USERNAME")"
	check 'nonroot zsh' test "$(getent passwd "$NONROOT_USERNAME" | cut -d: -f7)" = /usr/bin/zsh
fi

check 'Docker Compose' docker compose version
check 'Docker Buildx' docker buildx version
check 'Docker container execution' docker run --rm hello-world
printf '\nLocal checks passed. Verify fresh SSH, sudo, and Mosh sessions from another host.\n'
