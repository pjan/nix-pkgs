{ pkgs, sources }:

pkgs.buildNpmPackage {
  inherit (sources.chrome-devtools-mcp) pname version src;

  # This hash must be updated manually alongside the version in _sources/generated.nix.
  npmDepsHash = "sha256-VCa50F8KnOyc6Bwg80VNdPtFp5Kz2be8V+A0yltYEzw=";

  meta = with pkgs.lib; {
    description = "Chrome DevTools MCP server";
    homepage = "https://github.com/ChromeDevTools/chrome-devtools-mcp";
    license = licenses.asl20;
    mainProgram = "chrome-devtools-mcp";
  };
}
