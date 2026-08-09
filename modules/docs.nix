{
  pkgs,
  lib ? pkgs.lib,
  openchamber,
  ...
}:

let
  # Extend pkgs to include openchamber, which is used as the default for options.services.openchamber.package
  pkgsDocs = pkgs.extend (
    final: prev: {
      inherit openchamber;
    }
  );

  nixosEval = pkgsDocs.lib.evalModules {
    modules = [
      ./nixos.nix
      {
        options.systemd.services = pkgsDocs.lib.mkOption {
          type = pkgsDocs.lib.types.attrsOf pkgsDocs.lib.types.attrs;
          default = { };
        };
        options.users = pkgsDocs.lib.mkOption {
          type = pkgsDocs.lib.types.attrs;
          default = { };
          description = "Mock users option";
        };
      }
    ];
    specialArgs = {
      pkgs = pkgsDocs;
    };
  };
  nixosDocs = pkgsDocs.nixosOptionsDoc {
    options = builtins.removeAttrs nixosEval.options [
      "_module"
      "systemd"
      "users"
    ];
  };

  hmEval = pkgsDocs.lib.evalModules {
    modules = [
      ./home-manager.nix
      {
        options.systemd.user.services = pkgsDocs.lib.mkOption {
          type = pkgsDocs.lib.types.attrsOf pkgsDocs.lib.types.attrs;
          default = { };
        };
        # Mock home manager specific structures
        options.home = {
          homeDirectory = pkgsDocs.lib.mkOption {
            type = pkgsDocs.lib.types.str;
            default = "/home/user";
          };
        };
      }
    ];
    specialArgs = {
      pkgs = pkgsDocs;
    };
  };
  hmDocs = pkgsDocs.nixosOptionsDoc {
    options = builtins.removeAttrs hmEval.options [
      "_module"
      "systemd"
      "home"
    ];
  };
in
pkgsDocs.runCommand "openchamber-options-docs" { } ''
  mkdir -p $out

  # 1. Generate NixOS Options with clean relative paths and header
  cat << 'EOF' > $out/NIXOS_OPTIONS.md
  # NixOS Module Options

  This document details the configuration options available for the OpenChamber NixOS module.

  EOF
  sed -E \
    -e 's|\(file:///nix/store/[a-z0-9]{32}-source/|(../|g' \
    -e 's|/nix/store/[a-z0-9]{32}-source/|../|g' \
    -e 's|\\\.|\.|g' \
    ${nixosDocs.optionsCommonMark} >> $out/NIXOS_OPTIONS.md

  # 2. Generate Home Manager Options with clean relative paths and header
  cat << 'EOF' > $out/HOME_MANAGER_OPTIONS.md
  # Home Manager Module Options

  This document details the configuration options available for the OpenChamber Home Manager module.

  EOF
  sed -E \
    -e 's|\(file:///nix/store/[a-z0-9]{32}-source/|(../|g' \
    -e 's|/nix/store/[a-z0-9]{32}-source/|../|g' \
    -e 's|\\\.|\.|g' \
    ${hmDocs.optionsCommonMark} >> $out/HOME_MANAGER_OPTIONS.md
''
