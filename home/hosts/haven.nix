{ pkgs, ... }:
{
  imports = [
    ../common.nix
    ../programs/personal.nix
    ../programs/gaming.nix
    ../programs/speech.nix
    ../programs/zed.nix
    ../programs/proton-drive.nix
  ];

  home.packages = [ pkgs.dotnet-sdk ];
}
