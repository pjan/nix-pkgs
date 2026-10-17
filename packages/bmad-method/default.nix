{ pkgs, sources }:

pkgs.buildNpmPackage {
  inherit (sources.bmad-method) pname src;
  # nvfetcher reports the full tag (vX.Y.Z) as the version.
  version = pkgs.lib.removePrefix "v" sources.bmad-method.version;

  # Updated by scripts/update-deps.sh alongside the version in _sources/generated.nix.
  npmDepsHash = "sha256-yzyBy5siF1Ktbo0MobahkVCspzbBrsv7+tM8zps5Anw=";

  dontNpmBuild = true;

  meta = with pkgs.lib; {
    description = "Breakthrough Method for Agile AI-driven Development";
    homepage = "https://github.com/bmad-code-org/BMAD-METHOD";
    license = licenses.mit;
    mainProgram = "bmad";
  };
}
