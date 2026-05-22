{ pkgs, ... }:
{
  nix = {
    settings = {
      experimental-features = [ "nix-command" "flakes" ];
      auto-optimise-store = true;
    };
    gc = {
      automatic = true;
      dates = "weekly";
      options = "--delete-older-than 30d";
    };
  };

  nixpkgs.config.allowUnfree = true;

  time.timeZone = "Europe/London"; # TODO: your timezone
  i18n.defaultLocale = "en_GB.UTF-8";

  networking.networkmanager.enable = true;

  programs.fish.enable = true;

  programs.ssh.startAgent = true;

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
    noto-fonts-emoji
    material-design-icons
  ];

  environment.systemPackages = with pkgs; [
    wget
    git
    curl
    btop
    brightnessctl
    playerctl
    wl-clipboard
    grim
    slurp
  ];
}
