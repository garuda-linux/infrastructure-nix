#!/usr/bin/env bash
set -e
if test -f secrets/secrets/*; then
  ansible-vault decrypt secrets/secrets/* >/dev/null || true
fi

echo "[38;5;208mDecrypted all vaults![0m"
