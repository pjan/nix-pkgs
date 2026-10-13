{ pkgs, sources }:

pkgs.buildNpmPackage {
  inherit (sources.playwright-mcp) pname src;
  # nvfetcher reports the full tag (vX.Y.Z) as the version.
  version = pkgs.lib.removePrefix "v" sources.playwright-mcp.version;

  # Updated by scripts/update-npm-deps.sh alongside the version in _sources/generated.nix.
  npmDepsHash = "sha256-+uDq8oXkxQK4SNXBNZFtd4zrun1MGeSMeiLHViaNqHY=";

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
