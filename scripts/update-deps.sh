#!/usr/bin/env bash
# Refresh the pins that nvfetcher can't compute. Run after nvfetcher, from anywhere:
#   nix shell nixpkgs#nodejs nixpkgs#jq -c ./scripts/update-deps.sh
#
# 1. salesforce-cli: regenerate shrinkwrap-fixes.json (repairs upstream's npm-shrinkwrap.json).
# 2. Lockfiles for npm tarballs that ship without one (circle-cli, rea-agents).
# 3. npm deps hashes of the buildNpmPackage packages, vendor hashes of the buildGoModule ones.
#
# Step 3 builds with a fake hash and reads the real one from the mismatch error, so it
# needs direct network access (it fails behind TLS-intercepting proxies such as Zscaler).
set -euo pipefail

cd "$(dirname "$0")/.."

npm_packages=(bmad-method circle-cli playwright-mcp rea-agents salesforce-cli)
go_packages=(git-wt)
fake_hash="sha256-AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA="
system=$(nix eval --impure --raw --expr builtins.currentSystem)

work=$(mktemp -d)
trap 'rm -rf "$work"' EXIT

# Unpack a package's npm tarball into $work/package.
unpack() {
  local tarball
  tarball=$(nix build --no-link --print-out-paths ".#packages.$system.$1.src")
  rm -rf "$work/package"
  tar -xzf "$tarball" -C "$work"
}

echo "Regenerating salesforce-cli shrinkwrap fixes..."
unpack salesforce-cli
cp "$work/package/npm-shrinkwrap.json" "$work/upstream.json"
(cd "$work/package" && npm install --package-lock-only --ignore-scripts --legacy-peer-deps --no-audit --no-fund >/dev/null)
jq -n --slurpfile a "$work/upstream.json" --slurpfile b "$work/package/npm-shrinkwrap.json" '{
  remove: [$a[0].packages | keys[] | select(. as $k | $b[0].packages | has($k) | not)],
  set: ($b[0].packages | with_entries(select(.key as $k | $a[0].packages[$k] != .value)))
}' > packages/salesforce-cli/shrinkwrap-fixes.json

# Generate a lockfile for a tarball without one. $2 is the jq filter the package's
# postPatch applies to package.json; $3 extra npm flags.
generate_lockfile() {
  local pkg=$1 filter=$2
  shift 2
  echo "Regenerating $pkg lockfile..."
  unpack "$pkg"
  jq "$filter" "$work/package/package.json" > "$work/package.json.tmp"
  mv "$work/package.json.tmp" "$work/package/package.json"
  (cd "$work/package" && npm install --package-lock-only --ignore-scripts --no-audit --no-fund "$@" >/dev/null)
  cp "$work/package/package-lock.json" "packages/$pkg/package-lock.json"
}

generate_lockfile circle-cli 'del(.devDependencies)' --legacy-peer-deps
generate_lockfile rea-agents 'del(.devDependencies, .optionalDependencies, .scripts)'

# Replace a package's fixed-output hash: build $2 with a fake hash, read the real one.
update_hash() {
  local pkg=$1 attr=$2 file="packages/$1/default.nix" got
  echo "Updating $attr hash for $pkg..."
  # Matches `hash = "..."` (fetchNpmDeps), `npmDepsHash = "..."` and `vendorHash = "..."`.
  sed -E -i.bak "s|(ash = \")sha256-[A-Za-z0-9+/=]+(\")|\1${fake_hash}\2|" "$file"
  rm "$file.bak"
  got=$(nix build --no-link ".#packages.$system.$pkg.$attr" 2>&1 \
    | sed -nE 's/^ *got: *(sha256-[A-Za-z0-9+/=]+).*/\1/p' | head -n1 || true)
  if [[ -z "$got" ]]; then
    echo "error: could not determine $attr hash for $pkg" >&2
    exit 1
  fi
  sed -E -i.bak "s|${fake_hash}|${got}|" "$file"
  rm "$file.bak"
}

for pkg in "${npm_packages[@]}"; do update_hash "$pkg" npmDeps; done
for pkg in "${go_packages[@]}"; do update_hash "$pkg" goModules; done
