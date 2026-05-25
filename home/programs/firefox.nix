{ pkgs, lib, ... }:
{
  # DMS gates its pywalfox matugen template on `pywalfox` being in PATH
  # (core/internal/matugen/matugen.go: Commands: ["pywalfox"]). Without this,
  # `dms matugen check` reports pywalfox as not detected and silently skips
  # the template, so ~/.cache/wal/dank-pywalfox.json never gets written.
  # The native messaging manifest below already references the same package,
  # so this only adds a PATH entry.
  home.packages = [ pkgs.pywalfox-native ];

  # DMS's matugen template writes the pywal-format palette to
  # ~/.cache/wal/dank-pywalfox.json, but pywalfox hard-codes its read path to
  # ~/.cache/wal/colors.json (PYWAL_COLORS_PATH in pywalfox/config.py — no
  # override available). Bridge the two with a symlink so pywalfox finds it.
  home.activation.linkPywalColorsForPywalfox = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
    run mkdir -p "$HOME/.cache/wal"
    run ln -sf dank-pywalfox.json "$HOME/.cache/wal/colors.json"
  '';

  # Pywalfox native messaging manifest. The pywalfox-native nixpkgs package
  # does NOT ship a Firefox-discoverable manifest at
  # $out/lib/mozilla/native-messaging-hosts/, so programs.firefox.nativeMessagingHosts
  # is a no-op for it — Firefox returns "No such native application pywalfox".
  # The upstream workaround is `pywalfox install` (mutable, imperative);
  # declaring the manifest here keeps it reproducible. Firefox always reads
  # native-host manifests from ~/.mozilla/native-messaging-hosts/ regardless
  # of where the profile lives (it does not follow XDG for this path).
  home.file.".mozilla/native-messaging-hosts/pywalfox.json".text = builtins.toJSON {
    name = "pywalfox";
    description = "Pywalfox native messaging host";
    path = "${pkgs.pywalfox-native}/bin/pywalfox";
    type = "stdio";
    allowed_extensions = [ "pywalfox@frewacom.org" ];
  };

  programs.firefox = {
    enable = true;

    # Firefox on this host stores its profile under XDG_CONFIG_HOME instead of
    # the historical ~/.mozilla/firefox. home-manager has two paths to override:
    # configPath (where profiles.ini lives) and profilesPath (per-profile dirs).
    # profilesPath inherits from configPath on Linux, so setting configPath is
    # enough. Setting only profilesPath leaves profiles.ini in ~/.mozilla/firefox,
    # which Firefox then prefers — pointing it at a missing profile dir.
    configPath = ".config/mozilla/firefox";

    profiles.default = {
      id = 0;
      path = "lnrpqbjd.default";

      # DMS's firefox.css only defines CSS variables — it's a palette for a
      # Material userChrome theme that DMS doesn't ship. Pywalfox is what
      # actually paints the chrome; the @import below is kept only for the
      # font-family rule it sets at the bottom (and as a hook if a Material
      # userChrome ever gets added).
      userChrome = ''
        @import url("file:///home/seb/.config/DankMaterialShell/firefox.css");
      '';

      # userChrome.css is ignored unless this pref is on.
      settings."toolkit.legacyUserProfileCustomizations.stylesheets" = true;
    };
  };
}
