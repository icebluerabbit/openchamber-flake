{
  description = "Nix Flake for OpenChamber (AI Coding Agent GUI)";

  nixConfig = {
    extra-substituters = [
      "https://icebluerabbit-openchamber-flake.cachix.org"
    ];
    extra-trusted-public-keys = [
      "icebluerabbit-openchamber-flake.cachix.org-1:/9N8w45z9zJxCZHQ0yaB48hAzD4x9CasbhjOB4IGwyc="
    ];
  };

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    flake-parts.url = "github:hercules-ci/flake-parts";
    systems.url = "github:nix-systems/default";
  };

  outputs =
    inputs@{
      self,
      nixpkgs,
      flake-parts,
      ...
    }:
    flake-parts.lib.mkFlake { inherit inputs; } {
      systems = import inputs.systems;

      perSystem =
        {
          config,
          self',
          pkgs,
          system,
          ...
        }:
        {
          formatter = pkgs.nixfmt-tree;

          packages = rec {
            nodeModules = pkgs.callPackage ./pkgs/node-modules.nix { };
            openchamber = pkgs.callPackage ./pkgs/openchamber.nix { inherit nodeModules; };
            openchamber-desktop = pkgs.callPackage ./pkgs/openchamber-desktop.nix { inherit nodeModules; };
            docs = pkgs.callPackage ./modules/docs.nix { inherit openchamber; };
            default = openchamber;
          };

          apps.generate-docs = {
            type = "app";
            program = "${pkgs.writeShellScript "generate-docs" ''
              echo "==> Generating and copying OpenChamber options documentation..."
              mkdir -p docs
              cp -f ${self'.packages.docs}/NIXOS_OPTIONS.md docs/NIXOS_OPTIONS.md
              cp -f ${self'.packages.docs}/HOME_MANAGER_OPTIONS.md docs/HOME_MANAGER_OPTIONS.md
              echo "==> Done!"
            ''}";
          };

          apps.update-package = {
            type = "app";
            program = "${pkgs.writeShellScript "update-package" ''
              export PATH="${
                pkgs.lib.makeBinPath [
                  pkgs.nix
                  pkgs.nix-update
                  pkgs.nodejs
                  pkgs.git
                  pkgs.gnused
                  pkgs.gnugrep
                  pkgs.gawk
                  pkgs.coreutils
                ]
              }"
              ${builtins.readFile ./scripts/update-package.sh}
            ''}";
          };

          checks = pkgs.lib.optionalAttrs pkgs.stdenv.isLinux {
            openchamber-integration-test = pkgs.testers.runNixOSTest {
              name = "openchamber-integration-test";

              nodes.machine = { pkgs, ... }: {
                imports = [ self.nixosModules.openchamber ];

                services.openchamber = {
                  enable = true;
                  package = self'.packages.openchamber;
                };

                # Disable auto-start on boot in the VM so we can control startup sequence in the test script
                systemd.services.openchamber.wantedBy = pkgs.lib.mkForce [ ];
              };

              # Test script executed inside the virtual machine
              testScript = ''
                machine.wait_for_unit("network.target")
                machine.start_job("openchamber.service")
                try:
                    machine.wait_for_open_port(3000, timeout=60)
                    machine.succeed("curl -f http://127.0.0.1:3000/")
                except Exception as e:
                    machine.log(machine.succeed("journalctl -u openchamber.service --no-pager"))
                    raise e
              '';
            };
          };
        };

      flake = {
        nixosModules.openchamber = import ./modules/nixos.nix;
        nixosModules.default = self.nixosModules.openchamber;

        homeManagerModules.openchamber = import ./modules/home-manager.nix;
        homeManagerModules.default = self.homeManagerModules.openchamber;
      };
    };
}
