{ config, lib, pkgs, ... }:
let
  themedSlack = pkgs.callPackage ../../pkgs/slack-matugen { };
in
{
  home.packages = [ themedSlack ];
  # Also use the patched app when activating Home Manager before a system rebuild.
  xdg.dataFile."applications/slack.desktop".source = "${themedSlack}/share/applications/slack.desktop";
  # Firefox uses GIO to hand browser sign-in links back to the desktop app.
  # Register explicitly: the user-level desktop file can hide the package's
  # MIME cache entry, leaving GIO without a handler for slack:// links.
  xdg.mimeApps.defaultApplications."x-scheme-handler/slack" = "slack.desktop";
  xdg.mimeApps.associations.added."x-scheme-handler/slack" = [ "slack.desktop" ];

  xdg.configFile."matugen/config.toml".text = lib.mkAfter ''

    [templates.slack]
    input_path = '${config.xdg.configHome}/matugen/templates/slack.css'
    output_path = '${config.xdg.cacheHome}/matugen/slack.css'
    post_hook = '${pkgs.python3}/bin/python ${../../pkgs/slack-matugen/reload.py}'
  '';
  xdg.configFile."matugen/templates/slack.css".source = ../../pkgs/slack-matugen/theme.css;
}
