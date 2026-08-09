{
  lib,
  stdenv,
  bun,
  makeWrapper,
  electron,
  git,
  openssh,
  cloudflared,
  opencode,
  nodejs,
  nodeModules,
}:

let
  pname = "openchamber-desktop";
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

    # Build the static web assets and bundle main electron script
    bun run --cwd packages/electron build:web-assets
    bun run --cwd packages/electron bundle:main

    # Create symlink for resources folder so that isDev resource root resolution
    # resolves correctly relative to dist-bundle/main.mjs at runtime.
    ln -s ../resources packages/electron/dist-bundle/resources
  '';

  installPhase = ''
        mkdir -p $out/libexec/openchamber-desktop

        # Copy the package.json, packages, and node_modules folders
        cp -r package.json packages node_modules $out/libexec/openchamber-desktop/

        # Create symlink for workspace dependency @openchamber/web so that Node.js module resolution
        # resolves it correctly under the Electron application at runtime.
        mkdir -p $out/libexec/openchamber-desktop/node_modules/@openchamber
        ln -s ../../packages/web $out/libexec/openchamber-desktop/node_modules/@openchamber/web

        # Install the desktop icon (using SVG for scalable support)
        mkdir -p $out/share/icons/hicolor/scalable/apps
        cp packages/electron/resources/icons/app-icon.svg $out/share/icons/hicolor/scalable/apps/openchamber.svg

        # Install the desktop entry file
        mkdir -p $out/share/applications
        cat > $out/share/applications/openchamber.desktop <<EOF
    [Desktop Entry]
    Name=OpenChamber
    Comment=Desktop GUI client for OpenCode AI coding agent
    Exec=openchamber-desktop
    Icon=openchamber
    Type=Application
    Categories=Development;
    Terminal=false
    EOF

        # Create wrapped executable using standard Electron package pointing to the electron subfolder
        mkdir -p $out/bin
        makeWrapper ${electron}/bin/electron $out/bin/openchamber-desktop \
          --add-flags "$out/libexec/openchamber-desktop/packages/electron" \
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
    description = "Desktop GUI client for OpenCode AI agent";
    homepage = "https://github.com/openchamber/openchamber";
    license = licenses.mit;
    platforms = platforms.linux;
  };
}
