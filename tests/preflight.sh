#!/bin/bash
# Validation must reject bad input before setup can change access to a host.
set -euo pipefail

cd "$(dirname -- "${BASH_SOURCE[0]}")/.."
# shellcheck source=common.sh
source ./common.sh

for port in 0 65536 999999999999999999999 -1 abc ''; do
	if (
		SSH_PORT=$port
		validate_ssh_port
	) >/dev/null 2>&1; then
		echo "FAIL accepted SSH port: $port"
		exit 1
	fi
done
for port in 1 22 65535 00022; do
	(
		SSH_PORT=$port
		validate_ssh_port
	)
done
check_port=$(
	SSH_PORT=00022
	validate_ssh_port
	echo "$SSH_PORT"
)
[ "$check_port" = 22 ]
echo 'PASS SSH port validation and decimal normalization'

fixture=$(mktemp -d)
trap 'rm -rf "$fixture"' EXIT
SCRIPT_DIR=$fixture
ssh-keygen -q -t ed25519 -N '' -f "$fixture/generated"

for invalid_key in missing empty malformed private; do
	case "$invalid_key" in
	missing) rm -f "$fixture/key.pub" ;;
	empty) : >"$fixture/key.pub" ;;
	malformed) echo 'not a public key' >"$fixture/key.pub" ;;
	private) cp "$fixture/generated" "$fixture/key.pub" ;;
	esac
	if (validate_ssh_key) >/dev/null 2>&1; then
		echo "FAIL accepted $invalid_key SSH public key"
		exit 1
	fi
done
cp "$fixture/generated.pub" "$fixture/key.pub"
validate_ssh_key
echo 'PASS SSH public key validation'

bash setup.sh --help >/dev/null
if bash setup.sh --typo >/dev/null 2>&1; then
	echo 'FAIL accepted unknown setup argument'
	exit 1
fi
echo 'PASS CLI help and invalid arguments'
