{ config, inputs, pkgs, pkgs-ai-tools, ... }:
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

  # DMS reads user templates when generating a theme, but does not watch them.
  # Regenerate on activation when their configuration or contents change.
  systemd.user.services.dms.Unit.X-Restart-Triggers = [
    "${config.xdg.configFile."matugen/config.toml".source}"
    "${config.xdg.configFile."matugen/templates/t3-code.json".source}"
  ];

  # DMS merges user templates into each wallpaper/theme regeneration. Publish
  # the resulting theme through T3's CLI so running clients update as well.
  xdg.configFile."matugen/config.toml".text = ''
    [config]

    [templates]

    [templates.t3-code]
    input_path = '${config.xdg.configHome}/matugen/templates/t3-code.json'
    output_path = '${config.xdg.cacheHome}/matugen/t3-code.json'
    post_hook = '${pkgs-ai-tools.t3code}/bin/t3 theme set --id matugen ${config.xdg.cacheHome}/matugen/t3-code.json'
  '';

  xdg.configFile."matugen/templates/t3-code.json".text = ''
    {
      "name": "Matugen",
      "appearance": "{{mode}}",
      "canvas": "{{colors.surface.default.hex}}",
      "accent": "{{colors.primary.default.hex}}"
    }
  '';
}
