{ pkgs, sources }:

pkgs.buildNpmPackage {
  inherit (sources.chrome-devtools-mcp) pname src;
  # nvfetcher reports the full tag (chrome-devtools-mcp-vX.Y.Z) as the version.
  version = pkgs.lib.removePrefix "chrome-devtools-mcp-v" sources.chrome-devtools-mcp.version;

  # This hash must be updated manually alongside the version in _sources/generated.nix.
  # Reset to pkgs.lib.fakeHash and run `nix build .#chrome-devtools-mcp` to get the correct value.
  npmDeps = pkgs.fetchNpmDeps {
    inherit (sources.chrome-devtools-mcp) src;
    hash = "sha256-tLjVNhC8no+JeESBEsUdCxOT87sTO3lZbndbdVKC1Zs=";
    # Prevent puppeteer's postinstall from trying to download/setup Chrome
    # in the sandboxed fetchNpmDeps environment.
    npmFlags = [ "--ignore-scripts" ];
  };

  npmFlags = [ "--ignore-scripts" ];

  # devDependencies must be present during the bundle step (rollup needs them);
  # without this, npm prune --omit=dev removes them before rollup runs.
  dontNpmPrune = true;

  # Run `bundle` instead of `build`: tsc alone leaves a dangling relative import
  # (`../../node_modules/chrome-devtools-frontend/mcp/mcp.js`) that rollup resolves
  # and inlines. The `bundle` script runs: clean → build → rollup → rm build/node_modules.
  npmBuildScript = "bundle";

  # tsc over chrome-devtools-frontend exceeds V8's default heap on low-memory
  # machines (e.g. 7 GB GitHub runners), where Node sizes the heap from system RAM.
  env.NODE_OPTIONS = "--max-old-space-size=4096";

  # chrome-devtools-frontend TS sources and @paulirish/trace_engine .d.ts files both
  # declare ModelUpdateEvent from different module paths — TypeScript sees them as
  # incompatible (TS2717). tsc still emits JS when noEmitOnError is false (the default);
  # replacing && with ; lets the post-build step run past the type-error exit code.
  postPatch = ''
    ${pkgs.jq}/bin/jq '
      .scripts.build = "tsc --noEmitOnError false; node --experimental-strip-types --no-warnings=ExperimentalWarning scripts/post-build.ts"
    ' package.json > package.json.tmp
    mv package.json.tmp package.json
  '';

  meta = with pkgs.lib; {
    description = "Chrome DevTools MCP server";
    homepage = "https://github.com/ChromeDevTools/chrome-devtools-mcp";
    license = licenses.asl20;
    mainProgram = "chrome-devtools-mcp";
  };
}
