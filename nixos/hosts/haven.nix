{ pkgs, username, ... }:
{
  imports = [
    # Copy here after running `nixos-generate-config` on the machine
    # ./hardware-configuration.nix
    ../gaming.nix
  ];

  networking.hostName = "haven";

  # Enable niri session — also adds it to displayManager.sessionPackages.
  # niri-flake.nixosModules.niri auto-injects homeModules.config into HM
  # sharedModules, so user-level config in home/programs/niri.nix still works.
  programs.niri.enable = true;
  # DMS provides its own polkit agent; disable niri-flake's to avoid conflict.
  systemd.user.services.niri-flake-polkit.enable = false;

  # Bootloader — assumes UEFI. For legacy BIOS swap to grub.
  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;

  # DankGreeter — syncs DMS theme into the login screen
  programs.dank-material-shell.greeter = {
    enable = true;
    compositor.name = "niri";
    configHome = "/home/${username}"; # syncs your DMS theme to the greeter
    logs = {
      save = true;
      path = "/tmp/dms-greeter.log";
    };
  };

  # NVIDIA GPU (required for Wayland/niri)
  hardware.graphics.enable = true;
  services.xserver.videoDrivers = [ "nvidia" ];
  hardware.nvidia = {
    modesetting.enable = true;      # required for Wayland
    open = true;                    
    nvidiaSettings = true;
    powerManagement.enable = true;  # better suspend/resume on Wayland
  };

  users.users.${username} = {
    isNormalUser = true;
    extraGroups = [ "wheel" "networkmanager" "video" "audio" "input" ];
    shell = pkgs.fish;
  };

  # Set to the NixOS release you install with — do not change after initial install
  system.stateVersion = "25.11";
}
