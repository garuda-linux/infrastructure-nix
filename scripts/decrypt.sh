#!/usr/bin/env bash
set -e
if test -f nix/garuda/secrets/secrets.json; then
  ansible-vault decrypt nix/garuda/secrets/secrets.json >/dev/null || true
fi
if test -f secrets/*; then
  ansible-vault decrypt secrets/* >/dev/null || true
fi

echo "[38;5;208mDecrypted all vaults![0m"
