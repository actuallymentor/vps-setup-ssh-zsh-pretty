# vps-setup-ssh-zsh-pretty

Setup script to set up Ubuntu 24.04 and 26.04 LTS VPS servers the way I like them.

I advise adding your own SSH key into the script. Use this verbatim and you'll be giving me control of your servers.

Usage:

```bash
git clone https://github.com/actuallymentor/vps-setup-ssh-zsh-pretty.git setup && cd setup
# CHANGE THE key.pub FILE TO YOUR KEY
bash setup.sh
cd .. && rm -rf ./setup
```

Legacy silent mode skips firewall configuration and nonroot user creation:

```
bash setup.sh true
```

For a full unattended install, use `--noninteractive` and environment settings:

```bash
SSH_PORT=2222 FIREWALL=bidirectional bash setup.sh --noninteractive </dev/null
```

| Setting | Default | Values |
| --- | --- | --- |
| `SSH_PORT` | `22` | `1`–`65535` |
| `FIREWALL` | `incoming` | `incoming`, `bidirectional`, `n` (leave policy alone) |
| `AUTO_REBOOT_AT_UPGRADE` | `true` | `true`, `false` |
| `NONROOT_USERNAME` | empty | Optional sudo user; cannot be root/current/system account |
| `NONROOT_PASSWORD` | empty | Required for a new user; at least 8 characters |
| `NONROOT_SSH` | `y` | `y`, `n` |
| `NONINTERACTIVE` | `y` | `y`, `n`; controls package/configuration prompts |

Export `NONROOT_PASSWORD` from your secret store or a hidden `read -rs` prompt.
Existing user passwords and SSH keys are preserved. Existing accounts need a
usable password for password-based sudo. `--noninteractive` requires
`NONINTERACTIVE=y`; `bash setup.sh` asks for settings interactively.

## Mosh

Mosh is installed in every mode. Install the Mosh client locally, then connect:

```bash
mosh user@server
mosh --ssh="ssh -p 2222" user@server
```

Configured UFW policies allow incoming UDP `60000:61000`. Bidirectional mode
also permits replies from that source-port range, DNS, NTP, NTS key exchange
(TCP `4460`), and HTTP(S). Add the same incoming UDP range to any provider
firewall. Silent mode and `FIREWALL=n` leave Mosh firewall rules to you.

## Verification

```bash
make test  # Local syntax, ShellCheck, and preflight regression checks

# On the configured VPS, as root; match the settings used for installation:
SSH_PORT=2222 FIREWALL=bidirectional NONROOT_USERNAME=admin make verify
```

`make verify` checks services, effective SSH settings, firewall rules, mounts,
automatic updates, Zsh, Mosh, and a real Docker container. Also test a fresh
SSH login, sudo, and a Mosh session from another host. See [AUDIT.md](AUDIT.md)
for the compatibility test matrix and limits.

## Important notes:

1. Run on Ubuntu 24.04 or 26.04 LTS, as root or a sudo-capable login user. Keep the checkout outside `/tmp`, which setup mounts as tmpfs.
1. This will disable password-based authentication on your system, make sure you have an ssh key installed or you will not be able to SSH into your server **at all**.
	- An implicit assumption is that you run this script from a user that logs in via an ssh key.
	- When using a custom SSH port, verify the listener with `sudo ss -tlnp` and open a fresh `ssh -p PORT user@server` connection before closing your current session.
1. Automatic reboot after unattended upgrades defaults to `true`.
1. Swap setup intentionally disables existing swap and leaves the machine with only `/swapfile` configured by this script.
1. Docker is installed from Docker's Ubuntu apt repository for the detected Ubuntu codename.
1. Docker-published ports are not automatically protected by UFW; bind containers deliberately or add Docker firewall rules before exposing services.

If SSH becomes unreachable, use the provider console to inspect `sudo ufw status`,
`sudo sshd -t`, and `sudo systemctl status ssh.socket ssh.service`. Docker group
membership grants root-equivalent access.
