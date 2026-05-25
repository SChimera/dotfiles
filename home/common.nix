{ pkgs, username, ... }:
{
  imports = [
    ./programs/niri.nix
    ./programs/foot.nix
    ./programs/alacritty.nix
    ./programs/dms.nix
    ./programs/dsearch.nix
    ./programs/firefox.nix
    ./programs/git.nix
    ./programs/shell.nix
    ./programs/ssh.nix
  ];

  home.username = username;
  home.homeDirectory = "/home/${username}";

  home.packages = with pkgs; [
    vesktop
    wlogout
    pavucontrol
    nautilus
    imv
    mpv
    nodejs
    uv

    # User-scope GUI apps
    vscode
    neovim
    spotify
    protonvpn-gui
    claude-code

    # CLI staples
    ripgrep
    fd
    jq
    yq-go
    gh
    delta
    fastfetch

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

    # Cursor theme. Niri picks theme+size from its own `cursor` block
    # (see niri.nix), not from XCURSOR_THEME. The env var below is for
    # non-niri apps (and for niri's children, which niri then overwrites
    # to match its own block anyway).
    adwaita-icon-theme
  ];

  home.sessionVariables.XCURSOR_THEME = "Adwaita";

  programs.home-manager.enable = true;

  # Set once at first install — never change
  home.stateVersion = "25.11";
}
