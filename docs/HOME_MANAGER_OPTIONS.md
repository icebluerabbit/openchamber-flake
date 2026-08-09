# Home Manager Module Options

This document details the configuration options available for the OpenChamber Home Manager module.

## services.openchamber.enable



Whether to enable OpenChamber Web Interface.



*Type:*
boolean



*Default:*

```nix
false
```



*Example:*

```nix
true
```

*Declared by:*
 - [../modules/home-manager.nix](../modules/home-manager.nix)



## services.openchamber.package



The OpenChamber package to use.



*Type:*
package



*Default:*

```nix
pkgs.callPackage ../pkgs/openchamber.nix { }
```

*Declared by:*
 - [../modules/home-manager.nix](../modules/home-manager.nix)



## services.openchamber.dataDir

Storage directory for configurations, projects, and database.



*Type:*
string



*Default:*

```nix
${config.home.homeDirectory}/.config/openchamber
```

*Declared by:*
 - [../modules/home-manager.nix](../modules/home-manager.nix)



## services.openchamber.extraEnvironment



Additional custom environment variables to pass to the service.



*Type:*
attribute set of string



*Default:*

```nix
{ }
```

*Declared by:*
 - [../modules/home-manager.nix](../modules/home-manager.nix)



## services.openchamber.host



Host IP address the OpenChamber server binds to.



*Type:*
string



*Default:*

```nix
"127.0.0.1"
```

*Declared by:*
 - [../modules/home-manager.nix](../modules/home-manager.nix)



## services.openchamber.opencode.host



External OpenCode server base URL (e.g. http://127.0.0.1:4096).



*Type:*
null or string



*Default:*

```nix
null
```

*Declared by:*
 - [../modules/home-manager.nix](../modules/home-manager.nix)



## services.openchamber.opencode.hostname



Bind hostname for the managed OpenCode server.



*Type:*
null or string



*Default:*

```nix
null
```

*Declared by:*
 - [../modules/home-manager.nix](../modules/home-manager.nix)



## services.openchamber.opencode.port



Port of external OpenCode server to connect to.



*Type:*
null or 16 bit unsigned integer; between 0 and 65535 (both inclusive)



*Default:*

```nix
null
```

*Declared by:*
 - [../modules/home-manager.nix](../modules/home-manager.nix)



## services.openchamber.opencode.skipStart



Skip starting the managed OpenCode server (use external server instead).



*Type:*
boolean



*Default:*

```nix
false
```

*Declared by:*
 - [../modules/home-manager.nix](../modules/home-manager.nix)



## services.openchamber.port



Port the OpenChamber server listens on.



*Type:*
16 bit unsigned integer; between 0 and 65535 (both inclusive)



*Default:*

```nix
3000
```

*Declared by:*
 - [../modules/home-manager.nix](../modules/home-manager.nix)



## services.openchamber.settings



Declarative configuration options for OpenChamber’s \<filename>settings.json\</filename>.



*Type:*
open submodule of (JSON value)



*Default:*

```nix
{ }
```

*Declared by:*
 - [../modules/home-manager.nix](../modules/home-manager.nix)



## services.openchamber.settings.activeProjectId



ID of the currently active project.



*Type:*
string



*Default:*

```nix
""
```

*Declared by:*
 - [../modules/home-manager.nix](../modules/home-manager.nix)



## services.openchamber.settings.darkThemeId



Theme ID to use for dark mode.



*Type:*
string



*Default:*

```nix
"default"
```

*Declared by:*
 - [../modules/home-manager.nix](../modules/home-manager.nix)



## services.openchamber.settings.desktopLanAccessEnabled



Allow other computers on the LAN to connect.



*Type:*
boolean



*Default:*

```nix
false
```

*Declared by:*
 - [../modules/home-manager.nix](../modules/home-manager.nix)



## services.openchamber.settings.homeDirectory



Default home directory path for file browser.



*Type:*
string



*Default:*

```nix
""
```

*Declared by:*
 - [../modules/home-manager.nix](../modules/home-manager.nix)



## services.openchamber.settings.lastDirectory



Last opened directory path.



*Type:*
string



*Default:*

```nix
""
```

*Declared by:*
 - [../modules/home-manager.nix](../modules/home-manager.nix)



## services.openchamber.settings.lightThemeId



Theme ID to use for light mode.



*Type:*
string



*Default:*

```nix
"default"
```

*Declared by:*
 - [../modules/home-manager.nix](../modules/home-manager.nix)



## services.openchamber.settings.opencodeBinary



Path override to the opencode CLI binary.



*Type:*
string



*Default:*

```nix
""
```

*Declared by:*
 - [../modules/home-manager.nix](../modules/home-manager.nix)



## services.openchamber.settings.projects



List of project configurations.



*Type:*
list of anything



*Default:*

```nix
[ ]
```

*Declared by:*
 - [../modules/home-manager.nix](../modules/home-manager.nix)



## services.openchamber.settings.themeId



Active UI theme ID.



*Type:*
string



*Default:*

```nix
"default"
```

*Declared by:*
 - [../modules/home-manager.nix](../modules/home-manager.nix)



## services.openchamber.settings.themeVariant



Active theme variant.



*Type:*
one of “light”, “dark”



*Default:*

```nix
"dark"
```

*Declared by:*
 - [../modules/home-manager.nix](../modules/home-manager.nix)



## services.openchamber.settings.useSystemTheme



Use system color scheme preference.



*Type:*
boolean



*Default:*

```nix
true
```

*Declared by:*
 - [../modules/home-manager.nix](../modules/home-manager.nix)



## services.openchamber.uiPasswordFile



Path to a file containing the UI password.
The file must contain a line like:
OPENCHAMBER_UI_PASSWORD=your_password_here



*Type:*
null or absolute path



*Default:*

```nix
null
```

*Declared by:*
 - [../modules/home-manager.nix](../modules/home-manager.nix)


