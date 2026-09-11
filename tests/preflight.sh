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

for username in root nobody _audit; do
	if output=$(
		NONROOT_USERNAME=$username
		NONROOT_PASSWORD=''
		validate_nonroot_user
	); then
		echo "FAIL accepted unsafe username: $username"
		exit 1
	fi
	if ! grep -Eq 'valid Ubuntu username|Choose a nonroot user' <<<"$output"; then
		printf 'FAIL unexpected preflight output for %s:\n%s\n' "$username" "$output"
		exit 1
	fi
done
echo 'PASS unsafe account preflight'

NONROOT_USERNAME="audit-test-$RANDOM-$$"
for password in 1234567 $'12345678\n'; do
	if (
		NONROOT_PASSWORD=$password
		validate_nonroot_user
	) >/dev/null 2>&1; then
		echo 'FAIL accepted invalid password for a new user'
		exit 1
	fi
done
(
	NONROOT_PASSWORD=12345678
	validate_nonroot_user
)
echo 'PASS new account password validation and valid account accepted'
