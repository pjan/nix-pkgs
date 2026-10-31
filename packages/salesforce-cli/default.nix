{ pkgs, sources }:

let
  # Upstream dropped npm-shrinkwrap.json starting in 2.156.x.
  # package-lock.json is generated from the tarball by scripts/update-deps.sh.
  copyLockfile = ''
    cp ${./package-lock.json} package-lock.json
  '';
in

pkgs.buildNpmPackage {
  inherit (sources.salesforce-cli) pname version src;

  # Updated by scripts/update-deps.sh alongside the version in _sources/generated.nix.
  npmDeps = pkgs.fetchNpmDeps {
    inherit (sources.salesforce-cli) src;
    sourceRoot = "package";
    postPatch = copyLockfile;
    name = "salesforce-cli-${sources.salesforce-cli.version}-npm-deps";
    hash = "sha256-HsbE0gtQHwVN/FwjdNAAzA4G//wyl2nNiT2UDA9XrhQ=";
  };

  sourceRoot = "package";
  postPatch = copyLockfile;

  npmFlags = [
    "--legacy-peer-deps"
    "--omit=optional"
    "--ignore-scripts"
  ];

  dontNpmBuild = true;
  dontNpmPrune = true;

  meta = with pkgs.lib; {
    description = "Salesforce CLI";
    homepage = "https://github.com/salesforcecli/cli";
    license = licenses.bsd3;
    mainProgram = "sf";
  };
}
