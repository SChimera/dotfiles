{ inputs, pkgs, ... }:
{
  imports = [
    inputs.dms.homeModules.dank-material-shell
    inputs.dms.homeModules.niri
  ];

  programs.dank-material-shell = {
    enable = true;

    systemd = {
      enable = true;
      restartIfChanged = true;
    };

    # Core features
    enableSystemMonitoring = true;  # system monitoring widgets (dgop)
    enableVPN = true;               # VPN management widget
    enableDynamicTheming = true;    # wallpaper-based theming (matugen)
    enableAudioWavelength = true;   # audio visualizer (cava)
    enableCalendarEvents = true;    # calendar integration (khal)
    enableClipboardPaste = true;    # clipboard paste (wtype)

    # We import the niri integration module purely so its options exist; nothing
    # in the default include list (alttab/binds/colors/layout/outputs/wpblur) is
    # something DMS should own here — the hand-written niri config covers it.
    # Cursor was the one thing we *did* want from DMS, but DMS's "System Default"
    # theme resolves to whatever XCURSOR_THEME is at DMS startup, and niri itself
    # ignores that env at runtime (it reads its own `cursor` block) — so the
    # theme never round-trips. Cursor is set declaratively in niri.nix instead.
    niri.includes.filesToInclude = [ ];

    # dgop not in nixpkgs 25.11 stable — pull from its own flake
    dgop.package = inputs.dgop.packages.${pkgs.stdenv.hostPlatform.system}.default;
  };
}
