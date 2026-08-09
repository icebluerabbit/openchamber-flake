{ lib, pkgs }:

with lib;

lib.mkOption {
  type = types.submodule {
    freeformType = (pkgs.formats.json { }).type;

    options = {
      themeId = mkOption {
        type = types.str;
        default = "default";
        description = "Active UI theme ID.";
      };

      themeVariant = mkOption {
        type = types.enum [
          "light"
          "dark"
        ];
        default = "dark";
        description = "Active theme variant.";
      };

      useSystemTheme = mkOption {
        type = types.bool;
        default = true;
        description = "Use system color scheme preference.";
      };

      lightThemeId = mkOption {
        type = types.str;
        default = "default";
        description = "Theme ID to use for light mode.";
      };

      darkThemeId = mkOption {
        type = types.str;
        default = "default";
        description = "Theme ID to use for dark mode.";
      };

      lastDirectory = mkOption {
        type = types.str;
        default = "";
        description = "Last opened directory path.";
      };

      homeDirectory = mkOption {
        type = types.str;
        default = "";
        description = "Default home directory path for file browser.";
      };

      opencodeBinary = mkOption {
        type = types.str;
        default = "";
        description = "Path override to the opencode CLI binary.";
      };

      desktopLanAccessEnabled = mkOption {
        type = types.bool;
        default = false;
        description = "Allow other computers on the LAN to connect.";
      };

      projects = mkOption {
        type = types.listOf types.anything;
        default = [ ];
        description = "List of project configurations.";
      };

      activeProjectId = mkOption {
        type = types.str;
        default = "";
        description = "ID of the currently active project.";
      };
    };
  };
  default = { };
  description = ''
    Declarative configuration options for OpenChamber's <filename>settings.json</filename>.
  '';
}
