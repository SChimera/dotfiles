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
    vesktop
    fuzzel
    wlogout
    pavucontrol
    nautilus
    imv
    mpv

    # CLI staples
    ripgrep
    fd
    jq
    yq-go
    gh

    # k8s
    kubectl
    awscli2
    kubernetes-helm

    # Wayland / niri quality-of-life
    cliphist
    xwayland-satellite-unstable # paired with niri-unstable for X11 app support
    satty
    wf-recorder
    wev
  ];

  programs.home-manager.enable = true;

  # Set once at first install — never change
  home.stateVersion = "25.11";
}
