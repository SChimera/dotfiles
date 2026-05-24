{ pkgs, ... }:
{
  nix = {
    settings = {
      experimental-features = [ "nix-command" "flakes" ];
      trusted-users = [ "root" "@wheel" ];
    };
    gc = {
      automatic = true;
      dates = "weekly";
      options = "--delete-older-than 30d";
    };
    optimise = {
      automatic = true;
      dates = [ "weekly" ];
    };
  };

  nixpkgs.config.allowUnfree = true;

  i18n.defaultLocale = "en_DK.UTF-8";
  console.keyMap = "us";

  environment.sessionVariables = {
    NIXOS_OZONE_WL = "1"; # native Wayland for Electron/Chromium apps
  };

  networking.networkmanager.enable = true;

  programs.fish.enable = true;
  programs.dconf.enable = true;

  programs.ssh.startAgent = true;
  # niri-flake / gnome-keyring auto-enable gcr-ssh-agent, which conflicts with
  # openssh's agent. We want the explicit openssh agent above, so disable gcr's.
  services.gnome.gcr-ssh-agent.enable = false;

  # PipeWire audio
  services.pipewire = {
    enable = true;
    alsa.enable = true;
    alsa.support32Bit = true;
    pulse.enable = true;
    wireplumber.enable = true;
  };
  security.rtkit.enable = true;

  # Required for Wayland compositors
  security.polkit.enable = true;

  # XDG portals (niri uses xdg-desktop-portal-gnome or -gtk)
  xdg.portal = {
    enable = true;
    extraPortals = [
      pkgs.xdg-desktop-portal-gtk
      pkgs.xdg-desktop-portal-gnome
    ];
    config.common.default = "gtk";
  };

  hardware.bluetooth = {
    enable = true;
    powerOnBoot = true;
  };
  services.blueman.enable = true;

  fonts.packages = with pkgs; [
    nerd-fonts.jetbrains-mono
    nerd-fonts.noto
    noto-fonts
    noto-fonts-color-emoji
    material-design-icons
  ];

  environment.systemPackages = with pkgs; [
    wget
    git
    curl
    claude-code
    vscode
    neovim
    spotify
    unzip
    p7zip
    btop
    brightnessctl
    playerctl
    wl-clipboard
    grim
    slurp
  ];
}
