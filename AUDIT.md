# VPS verification

## 2026-09-15 — Ubuntu 24.04 / 26.04

| Check | Ubuntu 24.04.4 | Ubuntu 26.04 |
| --- | --- | --- |
| Full root setup + new `vpsadmin` account | Pass | Pass |
| Full direct nonroot setup | Interactive: pass | Noninteractive: pass |
| Full `sudo` setup from nonroot login | Noninteractive: pass | Legacy silent: pass |
| Fresh SSH login with newly installed keys | Pass | Pass |
| Preserve original keys, passwords, account list | Pass | Pass |
| Repair root-owned `.ssh` / `authorized_keys` | Pass | Pass |
| Ignore conflicting `NONROOT_*` settings | Pass | Pass |
| Services, mounts, swap, updates, SSH settings | Pass | Pass |
| UFW | Incoming: pass | Bidirectional: pass |
| Docker Compose, Buildx, real hello-world container | Pass | Pass |
| Fresh nonroot sudo, Docker, Zsh sessions | Pass | Pass |
| Live Mosh session over UDP | Pass | Pass |

Additional checks: interactive nonroot setup skips account prompts; keys with
no final newline survive; repeated installs leave one copy of each key; sudo
runs install keys for the login account without adding them to root. Ubuntu 26
also verifies removal of the invoking account's managed SSH deny while
preserving another account's deny. Both VPSes also verify migration of legacy
shared deny snippets for the invoking account and for another account.

Found and fixed: Ubuntu 26 `sudo-rs` rejects noninteractive `sudo -v` despite
NOPASSWD privileges. Probe `sudo -n true` before requesting authentication.
Fresh SSH connections were briefly refused during full package upgrades;
connections recovered automatically. Keep an established session during setup.

Local `make test`: ShellCheck, Bash syntax, preflight validation, and invoking
account selection pass. Live `tests/verify.sh` additionally checks nonroot SSH
ownership, permissions, and key validity.

Limits: x86_64 VPSes; passwordless sudo for unattended nonroot tests. No reboot
or password-prompt sudo test in this run.
