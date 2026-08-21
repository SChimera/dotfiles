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

    enableSystemMonitoring = true;  # system monitoring widgets (dgop)
    enableVPN = true;               # VPN management widget
    enableDynamicTheming = true;    # wallpaper-based theming (matugen)
    enableAudioWavelength = true;   # audio visualizer (cava)
    enableCalendarEvents = true;    # calendar integration (khal)
    enableClipboardPaste = true;    # clipboard paste (wtype)

    # Selectively include DMS-generated niri snippets. The hand-written niri
    # config in niri.nix still owns binds/layout/alttab; DMS owns:
    #   colors      — matugen-generated palette for focus-ring/border/etc.
    #                 (requires dropping any active-color/inactive-color lines
    #                 from niri.nix's focus-ring so DMS wins cleanly)
    #   outputs     — display config persisted via DMS Settings → Display
    #   wpblur      — wallpaper blur behind layer-shell surfaces
    #   windowrules — window rules added via DMS Settings → Window Rules
    # Cursor is deliberately excluded: DMS's "System Default" theme resolves to
    # whatever XCURSOR_THEME is at DMS startup, and niri ignores that env at
    # runtime (it reads its own `cursor` block) — so the theme never
    # round-trips. Cursor is set declaratively in niri.nix instead.
    niri.includes.filesToInclude = [ "colors" "outputs" "wpblur" "windowrules" ];
  };

  # Tools that splice binds directly into ~/.config/niri/config.kdl (jcode did
  # this before its removal) replace HM's symlink with a plain file, and the
  # next boot's home-manager-seb.service then fails with "Existing file
  # .../config.kdl would be clobbered". Force lets HM re-own the file on every
  # activation. "niri-config-dms" is the xdg.configFile attr name the DMS
  # module uses for its niri/config.kdl include shim.
  xdg.configFile."niri-config-dms".force = true;
}
