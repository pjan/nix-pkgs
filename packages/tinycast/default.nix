{ pkgs, sources }:

pkgs.stdenvNoCC.mkDerivation {
  inherit (sources.tinycast) pname version src;

  strictDeps = true;
  __structuredAttrs = true;

  dontPatch = true;
  dontConfigure = true;
  dontBuild = true;
  dontFixup = true;

  # DMG is APFS-formatted; undmg does not support APFS, so use 7zz instead.
  nativeBuildInputs = [ pkgs._7zz ];

  sourceRoot = "Tinycast.app";

  installPhase = ''
    runHook preInstall
    mkdir -p "$out/Applications/Tinycast.app"
    cp -R . "$out/Applications/Tinycast.app"
    runHook postInstall
  '';

  meta = with pkgs.lib; {
    description = "Native macOS launcher, hotkeys, and clipboard history";
    homepage = "https://github.com/abue-ammar/tinycast";
    license = licenses.agpl3Only;
    platforms = [
      "aarch64-darwin"
      "x86_64-darwin"
    ];
    sourceProvenance = with sourceTypes; [ binaryNativeCode ];
  };
}
