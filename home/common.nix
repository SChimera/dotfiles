{ inputs, pkgs, pkgs-unstable, pkgs-ai-tools, username, lib, ... }:
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
    ./programs/vesktop.nix
    ./programs/mimeapps.nix
  ];

  home.username = username;
  home.homeDirectory = "/home/${username}";

  home.packages = with pkgs; [
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
    pkgs-ai-tools.claude-code
    (pkgs.callPackage ../pkgs/codex {
      codex = inputs.codex-nix.packages.${pkgs.stdenv.hostPlatform.system}.default;
    })
    pkgs-ai-tools.t3code

    # CLI staples
    ripgrep
    fd
    jq
    yq-go
    gh
    delta
    fastfetch
    nix-output-monitor # `nom` — readable build tree; nh drives builds through it

    # k8s
    kubectl
    awscli2
    kubernetes-helm

    # Wayland / niri quality-of-life
    cliphist
    # 0.8.3 fixes Steam menus dismissing immediately. Remove this override
    # once our nixpkgs-unstable pin includes that release.
    (pkgs-unstable.xwayland-satellite.overrideAttrs (finalAttrs: _: {
      version = "0.8.3";
      src = pkgs-unstable.fetchFromGitHub {
        owner = "Supreeeme";
        repo = "xwayland-satellite";
        tag = "v0.8.3";
        hash = "sha256-eFEjCCniMCKeWU0PcZNv+tDYe08SLFPjRplyPY8OFt4=";
      };
      cargoDeps = pkgs-unstable.rustPlatform.fetchCargoVendor {
        inherit (finalAttrs) src;
        hash = "sha256-gMGFvnbxM3hD5fmkSimaFd87GEf6BXFe/MGjoS6VNVU=";
      };
    }))
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

  home.stateVersion = lib.mkDefault "25.11";
}
