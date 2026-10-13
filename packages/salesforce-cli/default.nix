{ pkgs, sources }:

let
  # Upstream's npm-shrinkwrap.json is inconsistent (e.g. missing nested
  # @opentelemetry/core versions, the macOS-only fsevents optional dep), so
  # `npm ci` fails offline. shrinkwrap-fixes.json turns it into what
  # `npm install --package-lock-only` produces: `remove` lists entries to drop,
  # `set` the entries to add or replace. scripts/update-npm-deps.sh regenerates it.
  patchShrinkwrap = ''
    jq --slurpfile f ${./shrinkwrap-fixes.json} \
      '.packages = ((.packages | delpaths([$f[0].remove[] | [.]])) + $f[0].set)' \
      npm-shrinkwrap.json > npm-shrinkwrap.json.tmp
    mv npm-shrinkwrap.json.tmp npm-shrinkwrap.json
  '';
in

pkgs.buildNpmPackage {
  inherit (sources.salesforce-cli) pname version src;

  # Updated by scripts/update-npm-deps.sh alongside the version in _sources/generated.nix.
  npmDeps = pkgs.fetchNpmDeps {
    inherit (sources.salesforce-cli) src;
    sourceRoot = "package";
    postPatch = patchShrinkwrap;
    name = "salesforce-cli-${sources.salesforce-cli.version}-npm-deps";
    hash = "sha256-OzujjLP1O/bNOnSis8abeJaEGfgBzglJ+Y5sZQoykTU=";
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
