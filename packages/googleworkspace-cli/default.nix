{ pkgs, sources }:

pkgs.stdenv.mkDerivation {
  inherit (sources.googleworkspace-cli) pname version src;

  sourceRoot = ".";

  nativeBuildInputs = [ pkgs.installShellFiles ];

  installPhase = ''
    runHook preInstall
    install -Dm755 gws $out/bin/gws
    runHook postInstall
  '';

  meta = with pkgs.lib; {
    description = "Google Workspace CLI — dynamic command surface from Discovery Service";
    homepage = "https://github.com/googleworkspace/cli";
    license = licenses.asl20;
    mainProgram = "gws";
    platforms = [ "aarch64-darwin" ];
  };
}
