{ pkgs, pkgs-unstable, pkgs-claude-code, username, ... }:
{
  imports = [
    ./programs/niri.nix
    ./programs/alacritty.nix
    ./programs/dms.nix
    ./programs/dsearch.nix
    ./programs/firefox.nix
    ./programs/git.nix
    ./programs/neovim.nix
    ./programs/shell.nix
    ./programs/ssh.nix
    ./programs/mimeapps.nix
  ];

  home.username = username;
  home.homeDirectory = "/home/${username}";

  home.packages = with pkgs; [
    discord
    vesktop
    wlogout
    pavucontrol
    kdePackages.dolphin
    kdePackages.breeze-icons # complete icon set so Dolphin/KDE widgets aren't missing icons
    kdePackages.breeze # Breeze widget style; plasma-integration selects it from kdeglobals
    kdePackages.kio-extras # extra KIO protocols (sftp/smb network browsing) + thumbnails
    kdePackages.kdegraphics-thumbnailers # image-format thumbnails in Dolphin
    kdePackages.ffmpegthumbs # video thumbnails in Dolphin
    kdePackages.ark # archive create/extract from Dolphin's context menu
    imv
    swayimg # minimal Wayland image viewer — default image handler (see programs/mimeapps.nix)
    kdePackages.gwenview # full KDE image viewer/editor; matches Breeze theming, available via Open With
    mpv
    nodejs
    python3
    uv

    # User-scope GUI apps
    ungoogled-chromium
    vscode
    spotify
    proton-vpn
    # Pinned ahead of nixpkgs (which lags at 2.1.193). Drop this override and
    # go back to plain pkgs-claude-code.claude-code once unstable catches up.
    (pkgs-claude-code.claude-code.overrideAttrs (_: rec {
      version = "2.1.197";
      src = pkgs-claude-code.fetchurl {
        url = "https://downloads.claude.ai/claude-code-releases/${version}/linux-x64/claude";
        hash = "sha256-9U5py8ibLaYaQVcAr3/1KhR+hiUX1PGw7s92hEjPf4M=";
      };
    }))

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
    xwayland-satellite-unstable
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

  # KDE/Qt theming for Dolphin et al. The KDE platform theme (plasma-integration)
  # is what builds the *full* QPalette from the matugen KColorScheme in kdeglobals.
  # Without it there is no Qt platform-theme plugin, so QPalette::Text (icon-view
  # label text) stays default-black while only the Breeze-drawn chrome/sidebar get
  # themed — the "legible sidebar, black folder names" bug. This module installs
  # kdePackages.plasma-integration and sets QT_QPA_PLATFORMTHEME=kde + QT_PLUGIN_PATH.
  # (Colors themselves come from DMS's kdeglobals; see qt-theming memory.)
  qt = {
    enable = true;
    platformTheme.name = "kde";
  };

  programs.home-manager.enable = true;

  home.stateVersion = "25.11";
}
