{ pkgs, sources }:

pkgs.buildNpmPackage {
  inherit (sources.playwright-mcp) pname version src;

  # This hash must be updated manually alongside the version in _sources/generated.nix.
  # Run: nix run nixpkgs#prefetch-npm-deps -- /path/to/playwright-mcp-<ver>/package-lock.json
  npmDepsHash = "sha256-MKCldBLhxEa4g9A3crj48bRbBfbnGbEntvf3aTgqYII=";

  # Prevent playwright from trying to download browsers in the sandbox.
  npmFlags = [ "--ignore-scripts" ];

  # The package is pre-built — cli.js ships in the repo.
  dontNpmBuild = true;

  meta = with pkgs.lib; {
    description = "Playwright Tools for MCP";
    homepage = "https://github.com/microsoft/playwright-mcp";
    license = licenses.asl20;
    mainProgram = "playwright-mcp";
  };
}
