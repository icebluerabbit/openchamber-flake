{
  config,
  lib,
  pkgs,
  ...
}:

with lib;

let
  cfg = config.services.openchamber;
  settingsFile = (pkgs.formats.json { }).generate "openchamber-settings.json" cfg.settings;
in
{
  options.services.openchamber = {
    enable = mkEnableOption "OpenChamber Web Interface";

    package = mkOption {
      type = types.package;
      default = pkgs.callPackage ../pkgs/openchamber.nix {
        nodeModules = pkgs.callPackage ../pkgs/node-modules.nix { };
      };
      defaultText = literalExpression "pkgs.callPackage ../pkgs/openchamber.nix { nodeModules = pkgs.callPackage ../pkgs/node-modules.nix { }; }";
      description = "The OpenChamber package to use.";
    };

    port = mkOption {
      type = types.port;
      default = 3000;
      description = "Port the OpenChamber server listens on.";
    };

    host = mkOption {
      type = types.str;
      default = "127.0.0.1";
      description = "Host IP address the OpenChamber server binds to.";
    };

    dataDir = mkOption {
      type = types.str;
      default = "/var/lib/openchamber";
      description = "Storage directory for configurations, projects, and database.";
    };

    uiPasswordFile = mkOption {
      type = types.nullOr types.path;
      default = null;
      description = ''
        Path to a file containing the UI password.
        The file must contain a line like:
        <programlisting>OPENCHAMBER_UI_PASSWORD=your_password_here</programlisting>
      '';
    };

    opencode = {
      host = mkOption {
        type = types.nullOr types.str;
        default = null;
        description = "External OpenCode server base URL (e.g. http://127.0.0.1:4096).";
      };

      port = mkOption {
        type = types.nullOr types.port;
        default = null;
        description = "Port of external OpenCode server to connect to.";
      };

      skipStart = mkOption {
        type = types.bool;
        default = false;
        description = "Skip starting the managed OpenCode server (use external server instead).";
      };

      hostname = mkOption {
        type = types.nullOr types.str;
        default = null;
        description = "Bind hostname for the managed OpenCode server.";
      };
    };

    extraEnvironment = mkOption {
      type = types.attrsOf types.str;
      default = { };
      description = "Additional custom environment variables to pass to the service.";
    };

    settings = import ./settings.nix { inherit lib pkgs; };
  };

  config = mkIf cfg.enable {
    systemd.services.openchamber = {
      description = "OpenChamber Daemon";
      after = [ "network.target" ];
      wantedBy = [ "multi-user.target" ];

      serviceConfig = {
        Type = "simple";
        User = "openchamber";
        Group = "openchamber";
        StateDirectory = "openchamber";
        WorkingDirectory = cfg.dataDir;

        ExecStartPre = pkgs.writeShellScript "openchamber-pre-start" ''
          mkdir -p ${cfg.dataDir}
          cp -f ${settingsFile} ${cfg.dataDir}/settings.json
          chmod 600 ${cfg.dataDir}/settings.json
        '';

        ExecStart = "${cfg.package}/bin/openchamber serve --foreground";
        EnvironmentFile = lib.optional (cfg.uiPasswordFile != null) cfg.uiPasswordFile;
        Restart = "on-failure";
        RestartSec = "5s";
      };

      environment = {
        OPENCHAMBER_DATA_DIR = cfg.dataDir;
        OPENCHAMBER_HOST = cfg.host;
        PORT = toString cfg.port;
      }
      // lib.optionalAttrs (cfg.opencode.host != null) {
        OPENCODE_HOST = cfg.opencode.host;
      }
      // lib.optionalAttrs (cfg.opencode.port != null) {
        OPENCODE_PORT = toString cfg.opencode.port;
      }
      // lib.optionalAttrs cfg.opencode.skipStart {
        OPENCODE_SKIP_START = "true";
      }
      // lib.optionalAttrs (cfg.opencode.hostname != null) {
        OPENCHAMBER_OPENCODE_HOSTNAME = cfg.opencode.hostname;
      }
      // cfg.extraEnvironment;
    };

    users.users.openchamber = {
      isSystemUser = true;
      group = "openchamber";
      description = "OpenChamber daemon user";
      home = cfg.dataDir;
    };
    users.groups.openchamber = { };
  };
}
