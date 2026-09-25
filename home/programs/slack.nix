{ config, lib, pkgs, ... }:
let
  themedSlack = pkgs.callPackage ../../pkgs/slack-matugen { };
in
{
  home.packages = [ themedSlack ];
  # Also use the patched app when activating Home Manager before a system rebuild.
  xdg.dataFile."applications/slack.desktop".source = "${themedSlack}/share/applications/slack.desktop";

  xdg.configFile."matugen/config.toml".text = lib.mkAfter ''

    [templates.slack]
    input_path = '${config.xdg.configHome}/matugen/templates/slack.css'
    output_path = '${config.xdg.cacheHome}/matugen/slack.css'
    post_hook = '${pkgs.python3}/bin/python ${../../pkgs/slack-matugen/reload.py}'
  '';
  xdg.configFile."matugen/templates/slack.css".source = ../../pkgs/slack-matugen/theme.css;
}
