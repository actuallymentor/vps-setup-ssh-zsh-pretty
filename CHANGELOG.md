# Changelog

## [Unreleased] - 2026-09-15

### Fixed

- migrate legacy SSH denies before repairing nonroot access (pending)
- support passwordless nonroot setup with Ubuntu 26 sudo-rs (pending)
- reuse the invoking nonroot account, including through sudo (pending)
- install SSH keys with correct ownership; preserve existing keys (pending)
- configure Zsh and Docker for the same invoking account (pending)

## [Unreleased] - 2026-09-11

### Added

- add Mosh with UDP 60000–61000 firewall access (80b04c7)
- add full `--noninteractive` mode with environment settings (80b04c7)
- add preflight regression tests and live VPS verification (80b04c7)

### Fixed

- allow DHCPv4/v6 client renewal through bidirectional UFW (5e930ee)

- support empty UFW rulesets and reject reserved accounts (75194ee)
- replace manually stored SSH denies before enabling UFW (5d3e990)

- open changed SSH ports before replacing listeners (80b04c7)
- restart SSH to discard inherited listeners (80b04c7)
- fix SSH firewall transitions and outgoing policy (80b04c7)
- allow NTS key exchange through bidirectional firewalls (80b04c7)
- preserve existing user keys and independent SSH restrictions (80b04c7)
- handle dpkg conffile prompts during unattended installation (80b04c7)
- reject invalid keys/ports and unsafe nonroot accounts (80b04c7)
- stop on swapoff failure and refresh generated mount units (80b04c7)
- install/verify Docker Engine and plugins despite an existing CLI (80b04c7)

- harden Ubuntu 26.04 setup safety and idempotency (pending)
- update Docker, SSH, fail2ban, swap, and apt flows (pending)
- handle socket-activated SSH when changing ports (pending)
- reload active SSH daemons after socket updates (pending)

### Changed

- support Ubuntu 24.04 and 26.04 LTS (80b04c7)

- document Ubuntu 26.04 target and intentional defaults (pending)
- note Docker-published ports bypass UFW by default (pending)
- add custom SSH port verification guidance (pending)
