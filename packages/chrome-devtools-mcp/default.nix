{ pkgs, sources }:

pkgs.buildNpmPackage {
  inherit (sources.chrome-devtools-mcp) pname version src;

  # This hash must be updated manually alongside the version in _sources/generated.nix.
  # Reset to pkgs.lib.fakeHash and run `nix build .#chrome-devtools-mcp` to get the correct value.
  npmDeps = pkgs.fetchNpmDeps {
    inherit (sources.chrome-devtools-mcp) src;
    hash = "sha256-VCa50F8KnOyc6Bwg80VNdPtFp5Kz2be8V+A0yltYEzw=";
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
