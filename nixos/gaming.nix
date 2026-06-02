{ pkgs, ... }:
{
  programs.steam = {
    enable = true;
    gamescopeSession.enable = true;
    remotePlay.openFirewall = true;
    localNetworkGameTransfers.openFirewall = true;
  };

  programs.gamescope = {
    enable = true;
    # capSysNice routes Steam's FHS sandbox through a *setuid* bwrap, but
    # bubblewrap 0.11.2 (NixOS 26.05) dropped setuid support, so Steam aborts
    # with "setuid use of bubblewrap is not supported in this build".
    # https://github.com/NixOS/nixpkgs/issues/523200
    capSysNice = false;
  };

  programs.gamemode.enable = true;

  # 32-bit support — required for DXVK, Wine, and many older games
  hardware.graphics.enable32Bit = true;
}
