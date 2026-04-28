{ pkgs, sources }:

let
  # The npm-shrinkwrap.json was generated on Linux and lacks the macOS-only
  # fsevents optional dep, causing `npm ci` to fail on Darwin.
  patchShrinkwrap = ''
    jq '.packages["node_modules/fsevents"] = {
      "version": "2.3.3",
      "resolved": "https://registry.npmjs.org/fsevents/-/fsevents-2.3.3.tgz",
      "integrity": "sha512-5xoDfX+fL7faATnagmWPpbFtwh/R77WmMMqqHGS65C3vvB0YHrgF+B1YmZ3441tMj5n63k0212XNoJwzlhffQw==",
      "optional": true,
      "os": ["darwin"],
      "engines": {"node": "^8.16.0 || ^10.6.0 || >=11.0.0"}
    }' npm-shrinkwrap.json > npm-shrinkwrap.json.tmp
    mv npm-shrinkwrap.json.tmp npm-shrinkwrap.json
  '';
in

pkgs.buildNpmPackage {
  inherit (sources.salesforce-cli) pname version src;

  # This hash must be updated manually alongside the version in _sources/generated.nix.
  npmDeps = pkgs.fetchNpmDeps {
    inherit (sources.salesforce-cli) src;
    sourceRoot = "package";
    postPatch = patchShrinkwrap;
    name = "salesforce-cli-${sources.salesforce-cli.version}-npm-deps";
    hash = "sha256-iRv3Pw50S6FNg3rIQTO8n/ZeY/3lrwWXjAkkaSVPHig=";
    nativeBuildInputs = [ pkgs.jq ];
  };

  sourceRoot = "package";
  postPatch = patchShrinkwrap;
  nativeBuildInputs = [ pkgs.jq ];

  npmFlags = [ "--legacy-peer-deps" "--omit=optional" "--ignore-scripts" ];

  dontNpmBuild = true;
  dontNpmPrune = true;

  meta = with pkgs.lib; {
    description = "Salesforce CLI";
    homepage = "https://github.com/salesforcecli/cli";
    license = licenses.bsd3;
    mainProgram = "sf";
  };
}
