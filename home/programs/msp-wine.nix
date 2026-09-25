{ config, pkgs, ... }:
let
  msp = import ../../pkgs/msp-wine { inherit pkgs; };
in
{
  home.packages = [ msp ];
  home.file.".local/bin/msp-wine-setup".source = "${msp}/bin/msp-wine-setup";
  home.file.".local/bin/msp1-fullscreen".source = "${msp}/bin/msp1-fullscreen";
  xdg.dataFile."applications/moviestarplanet.desktop".source = "${config.home.path}/share/applications/moviestarplanet.desktop";
  xdg.dataFile."applications/Charles.desktop".source = "${config.home.path}/share/applications/Charles.desktop";
  xdg.desktopEntries.Charles = {
    name = "Charles";
    genericName = "Web Debugging Proxy";
    # Java needs explicit font hints on niri; otherwise Charles's UI throws
    # when awt.font.desktophints is absent.
    exec = "${pkgs.coreutils}/bin/env _JAVA_AWT_WM_NONREPARENTING=1 JAVA_TOOL_OPTIONS=-Dawt.useSystemAAFontSettings=on ${pkgs.charles}/bin/charles %F";
    icon = "charles-proxy5";
    terminal = false;
    categories = [ "Network" "Development" "WebDevelopment" "Java" ];
    mimeType = [ "application/x-charles-savedsession" "application/x-charles-savedsession+xml" "application/x-charles-savedsession+json" "application/har+json" "application/vnd.tcpdump.pcap" "application/x-charles-trace" ];
    settings.StartupNotify = "true";
  };
  xdg.desktopEntries.moviestarplanet = {
    name = "MovieStarPlanet";
    exec = "${msp}/bin/msp1-fullscreen";
    terminal = false;
    categories = [ "Game" ];
    settings.StartupWMClass = "explorer.exe";
  };
  local.niri.extraConfig = ''
    window-rule {
      match app-id=r#"^explorer\.exe$"# title="^MSP1 "
      open-floating true
      open-focused true
      open-fullscreen false
      open-maximized-to-edges false
      min-width 2560
      max-width 2560
      min-height 1396
      max-height 1396
      default-column-width { fixed 2560; }
      default-window-height { fixed 1396; }
      default-floating-position x=0 y=0 relative-to="top-left"
    }
  '';
}
