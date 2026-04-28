# nix-pkgs

Custom Nix packages for [nix-config](https://github.com/pjan/nix-config). Single flake, packages + overlay.

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
nvfetcher -k foo # update only 'foo'
```

`nvfetcher` rewrites `_sources/generated.nix` with updated versions and hashes. Commit the result.
