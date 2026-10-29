{ pkgs, sources }:

let
  # The npm tarball ships prebuilt dist/ and the bundled skill, but no lockfile.
  # package-lock.json is generated from its package.json with dev/optional deps
  # (frida, whose install script downloads binaries) and scripts stripped;
  # scripts/update-deps.sh regenerates it.
  copyLockfile = ''
    cp ${./package-lock.json} package-lock.json
  '';
in

pkgs.buildNpmPackage (finalAttrs: {
  inherit (sources.rea-agents) pname version src;

  # Requires Node ^22.19 || ^24.11 || >=26.
  nodejs = pkgs.nodejs_24;

  # Updated by scripts/update-deps.sh alongside the version in _sources/generated.nix.
  npmDeps = pkgs.fetchNpmDeps {
    inherit (sources.rea-agents) src;
    sourceRoot = "package";
    postPatch = copyLockfile;
    name = "rea-agents-${sources.rea-agents.version}-npm-deps";
    hash = "sha256-I77F7iVdOfJabNXtQQLLOerp1jw5Qag6922AKD/CoSo=";
  };

  sourceRoot = "package";
  postPatch = copyLockfile + ''
    jq 'del(.devDependencies, .optionalDependencies, .scripts)' package.json > package.json.tmp
    mv package.json.tmp package.json
  '';
  nativeBuildInputs = [ pkgs.jq ];

  npmFlags = [ "--ignore-scripts" ];

  dontNpmBuild = true;

  passthru.skill = "${finalAttrs.finalPackage}/lib/node_modules/rea-agents/skills/reverse-engineer-anything";

  meta = with pkgs.lib; {
    description = "REA: reverse engineer anything — CLI and MCP server for agents";
    homepage = "https://github.com/morluto/rea";
    license = licenses.mit;
    mainProgram = "rea";
  };
})
