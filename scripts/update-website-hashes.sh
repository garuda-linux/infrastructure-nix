#!/usr/bin/env bash
set -euo pipefail

hash_of() {
  grep -m1 -oE 'got:[[:space:]]*sha256-[A-Za-z0-9+/=]+' | sed -E 's/^got:[[:space:]]*//'
}

for pkg in garuda-website garuda-startpage; do
  file="pkgs/$pkg/default.nix"

  for attr in srcHash pnpmDepsHash; do
    sed -i -E "s#($attr) = \"sha256-[^\"]+\";#\1 = pkgs.lib.fakeHash;#" "$file"

    out=$(nix build ".#$pkg" --no-link 2>&1 || true)
    new=$(hash_of <<<"$out" || true)

    if [ -z "$new" ]; then
      echo "could not resolve $attr for $pkg" >&2
      exit 1
    fi

    sed -i -E "s#($attr) = pkgs\.lib\.fakeHash;#\1 = \"$new\";#" "$file"
  done
done
