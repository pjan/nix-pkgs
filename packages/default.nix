{ pkgs }:
let
  sources = import ../_sources/generated.nix {
    inherit (pkgs) fetchgit fetchurl fetchFromGitHub dockerTools;
  };
in
{
  googleworkspace-cli = pkgs.callPackage ./googleworkspace-cli { inherit sources; };
  salesforce-cli = pkgs.callPackage ./salesforce-cli { inherit sources; };
  chrome-devtools-mcp = pkgs.callPackage ./chrome-devtools-mcp { inherit sources; };
  playwright-mcp = pkgs.callPackage ./playwright-mcp { inherit sources; };
}
