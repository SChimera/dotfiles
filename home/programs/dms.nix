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

    # dgop not in nixpkgs 25.11 stable — pull from its own flake
    dgop.package = inputs.dgop.packages.${pkgs.stdenv.hostPlatform.system}.default;

    # Upstream DMS ships its matugen foot template with a [colors-dark] section
    # header, but foot only knows [colors] — there are no theme-aware sections.
    # Foot prints "invalid section name: colors-dark" and skips the palette.
    # Patch the section header at install time so the file foot.ini includes
    # actually parses. Remove if/when upstream fixes the template.
    package = inputs.dms.packages.${pkgs.stdenv.hostPlatform.system}.dms-shell.overrideAttrs (old: {
      postInstall = (old.postInstall or "") + ''
        substituteInPlace $out/share/quickshell/dms/matugen/templates/foot.ini \
          --replace-fail '[colors-dark]' '[colors]'
      '';
    });
  };
}
