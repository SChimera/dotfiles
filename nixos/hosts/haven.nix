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
    # Keep the package's own nixpkgs pin. Backport the ENE speed conversion
    # fixed upstream after v0.8.0: the controller expects 0-100, not 0-255.
    # Without this, a 33% fan curve commands about 84% at the controller.
    package = inputs.lian-li-linux.packages.${pkgs.stdenv.hostPlatform.system}.default.overrideAttrs (old: {
      postPatch = (old.postPatch or "") + ''
        substituteInPlace crates/lianli-devices/src/ene6k77/controller.rs \
          --replace-fail '[REPORT_ID, 0x20 | group, 0x00, duty]' \
            '[REPORT_ID, 0x20 | group, 0x00, lianli_shared::fan::duty_to_percent(duty)]' \
          --replace-fail '[REPORT_ID, 0x20 | (group as u8), 0x00, duty]' \
            '[REPORT_ID, 0x20 | (group as u8), 0x00, lianli_shared::fan::duty_to_percent(duty)]'
      '';
    });
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
