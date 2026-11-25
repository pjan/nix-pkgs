{ pkgs, sources }:

let
  # Upstream dropped npm-shrinkwrap.json starting in 2.156.x.
  # package-lock.json is generated from the tarball by scripts/update-deps.sh.
  #
  # Since 2.158.x the root package.json declares bundleDependencies. One of them
  # (@oclif/plugin-plugins) depends on npm, so arborist treats npm's own bundled
  # deps as root-bundled and tries to fetch each one separately. They have no
  # `resolved` URL, so the offline install fails with ENOTCACHED. Root bundling
  # only matters for `npm pack`, so strip it (update-deps.sh applies the same filter).
  copyLockfile = ''
    cp ${./package-lock.json} package-lock.json
    ${pkgs.lib.getExe pkgs.jq} 'del(.bundleDependencies)' package.json > package.json.tmp
    mv package.json.tmp package.json
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
    hash = "sha256-Ou1FLCVonevXwbYCbu/xmXCCI3CXKHnZtZ45hV+GvvE=";
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
