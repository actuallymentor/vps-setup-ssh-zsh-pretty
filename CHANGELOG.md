# Changelog

## [Unreleased] - 2026-09-11

### Added

- install Mosh and configure UDP 60000–61000 firewall access
- add full `--noninteractive` mode with environment settings
- add preflight regression tests and live VPS verification

### Fixed

- open changed SSH ports before replacing listeners
- restart SSH to discard stale sockets in either activation mode
- remove conflicting port-22 rules and restore outgoing firewall policy
- allow NTS key exchange through bidirectional firewalls
- preserve existing user keys and independent SSH restrictions
- handle dpkg conffile prompts during unattended installation
- reject invalid ports, invalid keys, and unsafe nonroot account selections
- stop on swapoff failure and refresh generated mount units
- install and verify Docker Engine/plugins despite an existing CLI

- harden Ubuntu 26.04 setup safety and idempotency (pending)
- update Docker, SSH, fail2ban, swap, and apt flows (pending)
- handle socket-activated SSH when changing ports (pending)
- reload active SSH daemons after socket updates (pending)

### Changed

- support Ubuntu 24.04 and 26.04 LTS

- document Ubuntu 26.04 target and intentional defaults (pending)
- note Docker-published ports bypass UFW by default (pending)
- add custom SSH port verification guidance (pending)
