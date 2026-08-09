# OpenChamber Nix Flake

[![CI](https://github.com/icebluerabbit/openchamber-flake/actions/workflows/ci.yml/badge.svg)](https://github.com/icebluerabbit/openchamber-flake/actions/workflows/ci.yml)
[![Dependency Updates](https://github.com/icebluerabbit/openchamber-flake/actions/workflows/flake-update.yml/badge.svg)](https://github.com/icebluerabbit/openchamber-flake/actions/workflows/flake-update.yml)
[![Cachix Cache](https://img.shields.io/badge/Cachix-icebluerabbit--openchamber--flake-blue.svg)](https://icebluerabbit-openchamber-flake.cachix.org)
[![Nix Built](https://img.shields.io/badge/Nix-Flake-blue.svg?logo=nixos&logoColor=white)](https://nixos.org)

This repository provides a Nix Flake for [**OpenChamber**](https://github.com/openchamber/openchamber) (the web UI and Electron desktop client for the OpenCode AI coding agent), containing the web daemon service, the Electron GUI desktop application package, and a fully configurable NixOS service module.

---

## 📚 Documentation

*   [**NixOS Options (`docs/NIXOS_OPTIONS.md`)**](docs/NIXOS_OPTIONS.md): Configuration options for the NixOS system service module.

---

## ✨ Key Features

*   **Stateless Server Packaging**: Bundles and wraps the OpenChamber daemon with its runtime dependencies (`bun`, `git`, `openssh`, `cloudflared`, and `opencode`) directly into the final store path's `PATH`.
*   **Electron Desktop Client**: Packages the Electron GUI desktop app (`openchamber-desktop`) by compiling assets, bundling the main script, symlinking workspaces for ESM compatibility, and wrapping the standard Nixpkgs `electron` package.
*   **Fully Managed Declarative Config**: Exposes a structured, typed `settings` schema that automatically generates and manages OpenChamber's `settings.json` at startup, ensuring your Nix configuration is the single source of truth.
*   **Runtime Password Injection**: Safely loads database/UI authentication secrets at startup via `uiPasswordFile`, avoiding secret leaks in the read-only, world-readable Nix store.

---

## ❄️ Nix Integration

Add OpenChamber to your flake inputs:

```nix
{
  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    openchamber-flake.url = "github:icebluerabbit/openchamber-flake";
  };
}
```

### NixOS Module

Activate the module and declare daemon settings system-wide:

```nix
{ inputs, pkgs, ... }: {
  imports = [ inputs.openchamber-flake.nixosModules.default ];

  services.openchamber = {
    enable = true;
    port = 3000;
    host = "127.0.0.1";
    
    # Supply UI password securely from a secret file
    uiPasswordFile = "/run/secrets/openchamber-ui-password";

    # Declaratively manage OpenChamber's settings.json
    settings = {
      themeVariant = "dark";
      darkThemeId = "default";
      desktopLanAccessEnabled = false;
      showReasoningTraces = true;
    };
  };
}
```

### Install Desktop Client

Install the Electron GUI desktop application directly into your environment:

```nix
{ inputs, pkgs, ... }: {
  environment.systemPackages = [
    inputs.openchamber-flake.packages.${pkgs.system}.openchamber-desktop
  ];
}
```

---

## ⚙️ Advanced Customization (Package Overrides)

If you want to override the runtime packages or dependencies of the web daemon or desktop application, you can do so using the standard `.override` pattern:

```nix
environment.systemPackages = [
  (inputs.openchamber-flake.packages.${pkgs.system}.openchamber-desktop.override {
    # Use a custom opencode package override
    opencode = myCustomOpencodePackage;
  })
];
```

---

## 🛠️ Development & Utilities

### Run Integration Tests
Launch the QEMU VM integrated system check to verify that the systemd service starts, spawns `opencode`, and handles HTTP traffic:
```bash
nix flake check -L
```

### Regenerate Option Reference Manuals
Rebuild the markdown documentation files from the Nix module schemas:
```bash
nix run .#generate-docs
```

### Automatic Upgrades
The flake uses `nix-update` for automated weekly lockfile and package updates. To manually trigger a package upgrade, run:
```bash
nix-update openchamber --flake
```
