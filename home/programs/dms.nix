{ inputs, pkgs, ... }:
{
  imports = [
    inputs.dms.homeModules.dank-material-shell
    inputs.dms.homeModules.niri
  ];

  programs.dank-material-shell = {
    enable = true;

    niri = {
      enableSpawn = true;    # auto-starts DMS with niri — do NOT combine with systemd.enable
      enableKeybinds = true; # preset keybinds for launcher, notifications, settings
    };

    # Core features
    enableSystemMonitoring = true;  # system monitoring widgets (dgop)
    enableVPN = true;               # VPN management widget
    enableDynamicTheming = true;    # wallpaper-based theming (matugen)
    enableAudioWavelength = true;   # audio visualizer (cava)
    enableCalendarEvents = true;    # calendar integration (khal)
    enableClipboardPaste = true;    # clipboard paste (wtype)

    # dgop not in nixpkgs 25.11 stable — pull from its own flake
    dgop.package = inputs.dgop.packages.${pkgs.system}.default;
  };
}
