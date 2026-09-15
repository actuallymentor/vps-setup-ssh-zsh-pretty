# Audit environments

- `159.223.225.221` is the user-provided disposable audit VPS, not production.
- Last verified 2026-09-11: Ubuntu 26.04, root SSH on port 22; audit checkout `/root/vps-audit`.
- Use project-local `.ssh_key`; keep it private and uncommitted. The user may rebuild the VPS, so recheck identity and OS before further changes.
- Ubuntu 24 tests used a local disposable QEMU VM. See `AUDIT.md` for results and limits.

## 2026-09-15 nonroot setup audit

- User-provided disposable VPSes: Ubuntu 26.04 `146.190.217.254`; Ubuntu 24.04 `161.35.115.89`.
- Root checkout/logs: `/root/vps-audit`, `/root/setup-root.log`. Nonroot checkout/logs: `/home/vpsadmin/vps-audit`, `/home/vpsadmin/setup-*.log`.
- SSH port 22; project-local `.ssh_key` authenticates root and `vpsadmin`. Never transfer the private key.
- `vpsadmin` has passwordless sudo via `/etc/sudoers.d/90-vps-audit` for unattended testing. Random account passwords were not retained; root can reset them.
- Full apt upgrades can temporarily refuse fresh SSH connections. Keep a persistent control connection during remote audits.
