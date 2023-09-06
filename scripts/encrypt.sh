#!/usr/bin/env bash
set -e
if test -f secrets/secrets/*; then
	ansible-vault encrypt secrets/secrets/* >/dev/null || true
fi

echo "[38;5;208mEncrypted all vaults![0m"
