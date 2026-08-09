{
  lib,
  stdenv,
  bun,
  makeWrapper,
  git,
  openssh,
  cloudflared,
  nodejs,
  opencode,
  nodeModules,
}:

let
  pname = "openchamber";
  inherit (nodeModules) version src;
in
stdenv.mkDerivation {
  inherit pname version src;

  nativeBuildInputs = [
    bun
    makeWrapper
    nodejs
  ];

  buildPhase = ''
    export HOME=$TMPDIR

    # Copy root and package-specific node_modules from the FOD cache and make them writable
    cp -r ${nodeModules}/node_modules ./node_modules
    cp -r ${nodeModules}/packages ./
    chmod -R +w node_modules packages
    patchShebangs node_modules packages

    # Build the Vite frontend static files
    bun run build:web
  '';

  installPhase = ''
    mkdir -p $out/libexec/openchamber

    # Copy the package.json, packages, and node_modules folders
    cp -r package.json packages node_modules $out/libexec/openchamber/

    # Create wrapped executable using Bun runtime
    mkdir -p $out/bin
    makeWrapper ${bun}/bin/bun $out/bin/openchamber \
      --add-flags "$out/libexec/openchamber/packages/web/bin/cli.js" \
      --prefix PATH : ${
        lib.makeBinPath [
          git
          openssh
          cloudflared
          opencode
        ]
      } \
      --set NODE_ENV "production"
  '';

  meta = with lib; {
    description = "Web interface and daemon CLI for OpenCode AI agent";
    homepage = "https://github.com/openchamber/openchamber";
    license = licenses.mit;
    platforms = platforms.linux;
  };
}
