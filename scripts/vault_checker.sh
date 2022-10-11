#!/usr/bin/env bash
if test -f nix/garuda/secrets/*; then
  if (grep -q "\$ANSIBLE_VAULT;" <nix/garuda/secrets/*); then
    echo "[38;5;108mVault Encrypted. Safe to commit.[0m"
  else
    echo "[38;5;208mCleartext vault detected! Run ./scripts/encrypt.sh and try again.[0m"
    exit 1
  fi
fi

if test -f secrets/*; then
  if (grep -q "\$ANSIBLE_VAULT;" <secrets/*); then
    echo "[38;5;108mVault Encrypted. Safe to commit.[0m"
  else
    echo "[38;5;208mCleartext vault detected! Run ./scripts/encrypt.sh and try again.[0m"
    exit 1
  fi
fi
