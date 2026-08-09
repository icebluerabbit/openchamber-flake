#!/usr/bin/env bash
set -euo pipefail

# 1. Get current version from node-modules.nix
OLD_VERSION=$(nix eval --raw .#nodeModules.version)

echo "==> Current version: $OLD_VERSION"

# 2. Run nix-update to update the version and source hash
echo "==> Checking for updates using nix-update..."
# nix-update will update node-modules.nix
nix-update --flake nodeModules

NEW_VERSION=$(nix eval --raw .#nodeModules.version)
echo "==> Resolved version: $NEW_VERSION"

if [ "$OLD_VERSION" = "$NEW_VERSION" ]; then
    echo "==> Already up-to-date at version $NEW_VERSION."
    exit 0
fi

echo "==> Package bumped to $NEW_VERSION. Regenerating package-lock.json..."

# 3. Get the new source path from the Nix store
SRC_PATH=$(nix eval --raw .#nodeModules.src)
echo "==> Source path in Nix store: $SRC_PATH"

# 4. Create a temporary directory and copy the source package.json and workspaces
TMP_DIR=$(mktemp -d)
trap 'rm -rf "$TMP_DIR"' EXIT

echo "==> Preparing temporary workspaces in $TMP_DIR..."
# Copy root package.json and any package.json inside packages/*
cp "$SRC_PATH/package.json" "$TMP_DIR/"
mkdir -p "$TMP_DIR/packages"

# Copy package.json from all subdirectories under packages/
for d in "$SRC_PATH/packages"/*; do
    if [ -d "$d" ]; then
        name=$(basename "$d")
        mkdir -p "$TMP_DIR/packages/$name"
        if [ -f "$d/package.json" ]; then
            cp "$d/package.json" "$TMP_DIR/packages/$name/"
        fi
    fi
done

# Bypassing packageManager check and workspace: protocol in package.json files
sed -i '/"packageManager":/d' "$TMP_DIR/package.json"
sed -i -E 's/"workspace:[^"]*"/"*"/g' "$TMP_DIR/package.json"
for f in "$TMP_DIR/packages"/*/package.json; do
    if [ -f "$f" ]; then
        sed -i -E 's/"workspace:[^"]*"/"*"/g' "$f"
    fi
done

# 5. Generate the package-lock.json
cd "$TMP_DIR"
echo "==> Running npm to generate lockfile..."
npm install --package-lock-only --ignore-scripts --no-audit --no-fund

# 6. Copy the lockfile back to the flake repository
cd - >/dev/null
echo "==> Copying package-lock.json to pkgs/..."
cp "$TMP_DIR/package-lock.json" pkgs/package-lock.json

# 7. Temporarily write a dummy hash to node-modules.nix to force Nix to calculate the new hash
echo "==> Setting dummy hash to force recalculation..."
sed -i -E 's|npmDepsHash = "sha256-[^"]*";|npmDepsHash = "sha256-AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA=";|' pkgs/node-modules.nix

# 8. Run nix build to capture the correct hash from the mismatch error
echo "==> Running nix build to determine new npmDeps hash..."
# We run the build and expect it to fail with a hash mismatch, then extract the 'got:' hash
set +e
BUILD_OUTPUT=$(nix build .#nodeModules.npmDeps --no-link 2>&1)
set -e

NEW_HASH=$(echo "$BUILD_OUTPUT" | grep -o -E 'got:[[:space:]]+sha256-[A-Za-z0-9+/=]+' | awk '{print $2}' | head -n 1)

if [ -z "$NEW_HASH" ]; then
    echo "ERROR: Failed to extract new hash from build output!"
    echo "Build Output was:"
    echo "$BUILD_OUTPUT"
    exit 1
fi

echo "==> Found new hash: $NEW_HASH"

# 9. Update npmDepsHash in pkgs/node-modules.nix with the real hash
sed -i -E 's|npmDepsHash = "sha256-[^"]*";|npmDepsHash = "'"$NEW_HASH"'";|' pkgs/node-modules.nix

echo "==> Package update complete!"
