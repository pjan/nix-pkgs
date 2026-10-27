{ pkgs, sources }:

let
  # The npm tarball ships no lockfile, and its devDependencies include private
  # @circlefin-scoped packages that aren't on the public registry.
  # package-lock.json is generated from its package.json with devDependencies
  # stripped; scripts/update-deps.sh regenerates it.
  copyLockfile = ''
    cp ${./package-lock.json} package-lock.json
  '';
in

pkgs.buildNpmPackage {
  inherit (sources.circle-cli) pname version src;

  # Updated by scripts/update-deps.sh alongside the version in _sources/generated.nix.
  npmDeps = pkgs.fetchNpmDeps {
    inherit (sources.circle-cli) src;
    sourceRoot = "package";
    postPatch = copyLockfile;
    name = "circle-cli-${sources.circle-cli.version}-npm-deps";
    hash = "sha256-H8MigMiWnpqUNO1DcwBTDNMHABH58bV8yvWunDSjnKU=";
  };

  sourceRoot = "package";
  postPatch = copyLockfile + ''
    jq 'del(.devDependencies)' package.json > package.json.tmp
    mv package.json.tmp package.json
  '';
  nativeBuildInputs = [ pkgs.jq ];

  npmFlags = [
    "--omit=dev"
    "--legacy-peer-deps"
  ];

  dontNpmBuild = true;

  meta = with pkgs.lib; {
    description = "Circle CLI — command-line tool for interacting with Circle services";
    homepage = "https://www.npmjs.com/package/@circle-fin/cli";
    license = licenses.unfree;
    mainProgram = "circle";
  };
}
