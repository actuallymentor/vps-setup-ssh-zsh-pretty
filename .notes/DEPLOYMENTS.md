# Audit environments

- `159.223.225.221` is the user-provided disposable audit VPS, not production.
- Last verified 2026-09-11: Ubuntu 26.04, root SSH on port 22; audit checkout `/root/vps-audit`.
- Use project-local `.ssh_key`; keep it private and uncommitted. The user may rebuild the VPS, so recheck identity and OS before further changes.
- Ubuntu 24 tests used a local disposable QEMU VM. See `AUDIT.md` for results and limits.
