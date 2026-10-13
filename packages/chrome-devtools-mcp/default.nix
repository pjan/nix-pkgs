{ pkgs, sources }:

# Upstream publishes a prebuilt, dependency-free bundle to npm. Building from
# GitHub instead needs the devtools-frontend git submodule (~2.2 GB) and a tsc
# run that exceeds V8's default heap on CI runners.
pkgs.stdenv.mkDerivation {
  inherit (sources.chrome-devtools-mcp) pname version src;

  nativeBuildInputs = [ pkgs.makeWrapper ];

  installPhase = ''
    runHook preInstall

    mkdir -p $out/lib/chrome-devtools-mcp $out/bin
    cp -r . $out/lib/chrome-devtools-mcp

    makeWrapper ${pkgs.nodejs}/bin/node $out/bin/chrome-devtools-mcp \
      --add-flags $out/lib/chrome-devtools-mcp/build/src/bin/chrome-devtools-mcp.js
    makeWrapper ${pkgs.nodejs}/bin/node $out/bin/chrome-devtools \
      --add-flags $out/lib/chrome-devtools-mcp/build/src/bin/chrome-devtools.js

    runHook postInstall
  '';

  meta = with pkgs.lib; {
    description = "Chrome DevTools MCP server";
    homepage = "https://github.com/ChromeDevTools/chrome-devtools-mcp";
    license = licenses.asl20;
    mainProgram = "chrome-devtools-mcp";
  };
}
