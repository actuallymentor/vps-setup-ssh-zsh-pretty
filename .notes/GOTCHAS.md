# Gotchas

- Target runtimes are Ubuntu 24.04 and 26.04 LTS.
- Automatic reboot after unattended upgrades intentionally defaults to `true`.
- Swap setup intentionally removes existing swap configuration so the script-owned `/swapfile` is the only configured swap.
- `babysit.yaml` is local automation config and should stay out of setup-script changes unless explicitly requested.
- UFW `insert`/`prepend` treat opposite-action rules as existing matches; an old deny can prevent inserting an allow. Test fresh SSH connections after port changes.
- Switching away from SSH socket activation requires a service restart to discard inherited listeners; a reload can retain the old port.
- Stage remote audit copies under a home directory, replace their `key.pub` with the audit public key, and never transfer or commit `.ssh_key`.
- UFW `insert 1` rejects an empty ruleset; `prepend` supports fresh installs.
- Disabled UFW retains rules; clear a stored deny for the chosen SSH port before enabling the firewall.
