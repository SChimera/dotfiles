{ pkgs, username, ... }:
{
  imports = [
    ./programs/niri.nix
    ./programs/foot.nix
    ./programs/dms.nix
    ./programs/git.nix
    ./programs/shell.nix
    ./programs/ssh.nix
  ];

  home.username = username;
  home.homeDirectory = "/home/${username}";

  home.packages = with pkgs; [
    firefox
    fuzzel
    swaylock
    swayidle
    wlogout
    pavucontrol
    nautilus
    imv
  ];

  programs.home-manager.enable = true;

  # Set once at first install — never change
  home.stateVersion = "25.11";
}
