{
  lib,
  buildNpmPackage,
  fetchFromGitHub,
}:

let
  pname = "openchamber";
  version = "1.23.1";

  src = fetchFromGitHub {
    owner = "openchamber";
    repo = "openchamber";
    rev = "v${version}";
    hash = "sha256-GcyIybBNfaBRUgbUrIlOJFnPOBvlCNCFIWUGFEkHIM8=";
  };
in
buildNpmPackage {
  pname = "${pname}-node-modules";
  inherit version src;

  postPatch = ''
    cp ${./package-lock.json} package-lock.json
    chmod +w package-lock.json

    # Clean package.json files to make them NPM workspaces compatible
    sed -i '/"packageManager":/d' package.json
    sed -i -E 's/"workspace:[^"]*"/"*"/g' package.json
    for f in packages/*/package.json; do
      if [ -f "$f" ]; then
        sed -i -E 's/"workspace:[^"]*"/"*"/g' "$f"
      fi
    done
  '';

  # We use a dummy hash first to force Nix to compute the real npmDepsHash for us
  npmDepsHash = "sha256-UNUQad1eeu2afQSZU+d/x/wHW0gYRGw4aoR78NoE7IQ=";

  makeCacheWritable = true;

  npmFlags = [ "--ignore-scripts" ];

  dontBuild = true;

  installPhase = ''
    mkdir -p $out
    cp -r node_modules $out/

    # Copy package-specific node_modules directories for monorepo workspaces
    for dir in packages/*; do
      if [ -d "$dir/node_modules" ]; then
        mkdir -p "$out/$dir"
        cp -r "$dir/node_modules" "$out/$dir/"
      fi
    done

    # Remove dangling local workspace symlinks to pass Nix sanity checks
    rm -rf $out/node_modules/@openchamber
    rm -rf $out/node_modules/openchamber
    rm -f $out/node_modules/.bin/openchamber
  '';
}
