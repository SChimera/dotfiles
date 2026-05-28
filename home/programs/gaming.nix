{ pkgs, ... }:
{
  home.packages = with pkgs; [
    mangohud    # in-game overlay: FPS, frametimes, GPU/CPU temps, VRAM
    lutris      # game launcher for GOG, Epic, Battle.net, etc.
    protontricks # apply winetricks verbs to Steam Proton prefixes
    protonup-qt # GUI installer for GE-Proton (better game compatibility than stock Proton)
  ];
}
