# Gotchas

- Target runtime is Ubuntu 26.04 LTS.
- Automatic reboot after unattended upgrades intentionally defaults to `true`.
- Swap setup intentionally removes existing swap configuration so the script-owned `/swapfile` is the only configured swap.
- `babysit.yaml` is local automation config and should stay out of setup-script changes unless explicitly requested.
