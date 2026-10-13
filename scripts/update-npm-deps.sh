#!/usr/bin/env bash
# Refresh the npm pins that nvfetcher can't compute. Run after nvfetcher, from anywhere:
#   nix shell nixpkgs#nodejs nixpkgs#jq -c ./scripts/update-npm-deps.sh
#
# 1. salesforce-cli: regenerate shrinkwrap-fixes.json (repairs upstream's npm-shrinkwrap.json).
# 2. npm deps hashes of the buildNpmPackage packages.
#
# Step 2 builds with a fake hash and reads the real one from the mismatch error, so it
# needs direct network access (it fails behind TLS-intercepting proxies such as Zscaler).
set -euo pipefail

cd "$(dirname "$0")/.."

npm_packages=(playwright-mcp salesforce-cli)
fake_hash="sha256-AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA="
system=$(nix eval --impure --raw --expr builtins.currentSystem)

echo "Regenerating salesforce-cli shrinkwrap fixes..."
tarball=$(nix build --no-link --print-out-paths ".#packages.$system.salesforce-cli.src")
work=$(mktemp -d)
trap 'rm -rf "$work"' EXIT
tar -xzf "$tarball" -C "$work"
cp "$work/package/npm-shrinkwrap.json" "$work/upstream.json"
(cd "$work/package" && npm install --package-lock-only --ignore-scripts --legacy-peer-deps --no-audit --no-fund >/dev/null)
jq -n --slurpfile a "$work/upstream.json" --slurpfile b "$work/package/npm-shrinkwrap.json" '{
  remove: [$a[0].packages | keys[] | select(. as $k | $b[0].packages | has($k) | not)],
  set: ($b[0].packages | with_entries(select(.key as $k | $a[0].packages[$k] != .value)))
}' > packages/salesforce-cli/shrinkwrap-fixes.json

for pkg in "${npm_packages[@]}"; do
  file="packages/$pkg/default.nix"
  echo "Updating npm deps hash for $pkg..."
  # Matches both `hash = "..."` (fetchNpmDeps) and `npmDepsHash = "..."`.
  sed -E -i.bak "s|(ash = \")sha256-[A-Za-z0-9+/=]+(\")|\1${fake_hash}\2|" "$file"
  rm "$file.bak"
  got=$(nix build --no-link ".#packages.$system.$pkg.npmDeps" 2>&1 \
    | sed -nE 's/^ *got: *(sha256-[A-Za-z0-9+/=]+).*/\1/p' | head -n1 || true)
  if [[ -z "$got" ]]; then
    echo "error: could not determine npm deps hash for $pkg" >&2
    exit 1
  fi
  sed -E -i.bak "s|${fake_hash}|${got}|" "$file"
  rm "$file.bak"
done
