# nix-pkgs

Custom Nix packages. Single flake, packages + overlay.

## Structure

```
flake.nix          # exposes overlays.default and packages.${system}.*
nvfetcher.toml     # version sources; run nvfetcher to regenerate _sources/
packages/          # one directory per package, called from packages/default.nix
```

## Using in nix-config

Add as a flake input:

```nix
inputs.nix-pkgs.url = "github:pjan/nix-pkgs";
```

Apply the full overlay (makes all packages available as if they were in nixpkgs):

```nix
nixpkgs.overlays = [ inputs.nix-pkgs.overlays.default ];
```

Or pull individual packages directly:

```nix
environment.systemPackages = [
  inputs.nix-pkgs.packages.${system}.tool-name
];
```

## Adding a package

1. Add a source entry to `nvfetcher.toml`, then run `nvfetcher` to generate `_sources/generated.nix`.
2. Create `packages/tool-name/default.nix`.
3. Register it in `packages/default.nix`:
   ```nix
   tool-name = pkgs.callPackage ./tool-name { };
   ```
4. Test the build in isolation:
   ```sh
   nix build .#tool-name
   ```

## Updating versions

```sh
nvfetcher        # update all sources
nvfetcher -f foo # update only 'foo'
```

`nvfetcher` rewrites `_sources/generated.nix` with updated versions and hashes. Then refresh the
pins nvfetcher can't compute (npm deps and Go vendor hashes, lockfiles for npm tarballs that ship
without one, salesforce-cli shrinkwrap fixes):

```sh
nix shell nixpkgs#nodejs nixpkgs#jq -c ./scripts/update-deps.sh
```

New `buildNpmPackage`/`buildGoModule` packages go in the `npm_packages`/`go_packages` lists there.

Commit the result. The daily `Update package sources` workflow does all of this, builds every
package, and only commits the result to `main` when the build succeeds.

Unfree packages (circle-cli) must be allowed in the consumer's nixpkgs config; the flake's own
`packages`/`checks` allow them via `allowUnfreePredicate`.
