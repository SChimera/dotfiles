{ pkgs, inputs, username, ... }:
{
  imports = [
    ./haven-hardware.nix
    ../desktop.nix
    inputs.lian-li-linux.nixosModules.default
    ../gaming.nix
  ];

  networking.hostName = "haven";

  services.lianli = {
    enable = true;
    # Preserve the upstream package/cache instead of rebuilding against our nixpkgs.
    package = inputs.lian-li-linux.packages.${pkgs.stdenv.hostPlatform.system}.default;
  };

  # NVIDIA GPU (required for Wayland/niri)
  services.xserver.videoDrivers = [ "nvidia" ];
  hardware.nvidia = {
    modesetting.enable = true;
    open = true;
    nvidiaSettings = true;
    powerManagement.enable = true;  # better suspend/resume on Wayland
  };

  services.ollama = {
    enable = true;
    package = pkgs.ollama-cuda;
  };

  # Disko creates the extra btrfs subvolumes as root:root 755, so the user
  # can't write to them. Chown the mount points (not their contents) on each
  # activation so the file manager can create folders without sudo.
  systemd.tmpfiles.rules = [
    "d /games 0755 ${username} users -"
    "d /data  0755 ${username} users -"
  ];

  # Set to the NixOS release you install with — do not change after initial install
  system.stateVersion = "25.11";
}
