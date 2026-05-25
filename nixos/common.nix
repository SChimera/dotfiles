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

  # In-RAM compressed swap. No disk swap configured — at 64 GB RAM the
  # T705's endurance is better spent on the Nix store than on paging.
  zramSwap = {
    enable = true;
    algorithm = "zstd";
    memoryPercent = 50;
  };

  # Tuning that pairs with zram (push to compressed swap before evicting cache).
  boot.kernel.sysctl = {
    "vm.swappiness" = 180;
    "vm.watermark_boost_factor" = 0;
    "vm.watermark_scale_factor" = 125;
    "vm.page-cluster" = 0;
  };

  # /tmp in RAM — fast builds, automatic cleanup, no SSD wear.
  boot.tmp.useTmpfs = true;

  # Nix build parallelism — let it use the full 8c/16t.
  nix.settings.max-jobs = "auto";
  nix.settings.cores = 0;

  # Periodic btrfs scrub catches silent corruption on all mounted btrfs FS.
  services.btrfs.autoScrub = {
    enable = true;
    interval = "monthly";
  };

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

  services.udisks2.enable = true;
  services.gvfs.enable = true;

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
    unzip
    p7zip
    btop
    brightnessctl
    playerctl
    wl-clipboard
    grim
    slurp
    bun
  ];
}
