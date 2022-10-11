#!/usr/bin/env bash
set -e
if test -f nix/garuda/secrets/secrets.json; then
  ansible-vault encrypt nix/garuda/secrets/secrets.json >/dev/null || true
fi
if test -f secrets/*; then
  ansible-vault encrypt secrets/* >/dev/null || true
fi

echo "[38;5;208mEncrypted all vaults![0m"
