{ pkgs, ... }:
{
  imports = [
    ../common.nix
    ../programs/gaming.nix
    ../programs/speech.nix
    ../programs/zed.nix
    ../programs/proton-drive.nix
  ];

  local.niri.keyboardLayout = "us,dk";
  local.niri.extraBinds = ''
    Mod+Alt+Space { switch-layout "next"; }
  '';

  home.packages = [ pkgs.dotnet-sdk ];
}
