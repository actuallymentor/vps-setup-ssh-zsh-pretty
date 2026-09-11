#!/bin/bash
set -euo pipefail

echo "Running package upgrade"

# shellcheck source=common.sh
source "$(dirname -- "${BASH_SOURCE[0]}")/common.sh"

# Update repos
apt_get update

echo "Starting update process"
apt_get install -y apt

apt_get upgrade -y
apt_get dist-upgrade -y
apt_get autoremove -y

echo "Package upgrade done"
