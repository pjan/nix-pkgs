{ pkgs, sources }:

pkgs.buildGoModule (finalAttrs: {
  inherit (sources.git-wt) pname src;
  # nvfetcher reports the full tag (vX.Y.Z) as the version.
  version = pkgs.lib.removePrefix "v" sources.git-wt.version;

  # Updated by scripts/update-deps.sh alongside the version in _sources/generated.nix.
  vendorHash = "sha256-4oGxkBdKUARLPbsl0lUdTZ3x4tyYD014dBaB6tyxI1w=";

  subPackages = [ "cmd/git-wt" ];

  ldflags = [
    "-s"
    "-w"
    "-X github.com/ahmedelgabri/git-wt/internal/cmd.Version=${finalAttrs.version}"
  ];

  nativeBuildInputs = [ pkgs.git ];

  meta = with pkgs.lib; {
    description = "Git worktree manager";
    homepage = "https://github.com/ahmedelgabri/git-wt";
    license = licenses.mit;
    mainProgram = "git-wt";
  };
})
