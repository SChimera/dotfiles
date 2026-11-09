# Framework Laptop 13 Pro, Intel Core Ultra X7 358H, 32 GB RAM.
{ inputs, pkgs, username, ... }:
{
  imports = [
    inputs.nixos-hardware.nixosModules.framework-intel-core-ultra-series3
    ./framework-hardware.nix
    ./framework-secure-boot.nix
    ../desktop.nix
  ];

  networking.hostName = "framework";
  # Framework recommends kernel 7.0+ for Intel Core Ultra Series 3.
  boot.kernelPackages = pkgs.linuxPackages_latest;

  services.power-profiles-daemon.enable = true;
  # DMS reads battery charge and charging state through UPower.
  services.upower.enable = true;

  services.printing.enable = true;

  services.tailscale = {
    enable = true;
    openFirewall = true;
    # Allow using exit nodes and subnet routes selected in Dankscale.
    useRoutingFeatures = "client";
    # Let the desktop plugin manage Tailscale without root prompts.
    extraSetFlags = [ "--operator=${username}" ];
  };

  # OpenVPN 3 needs its D-Bus services as well as the command-line client.
  # Let NetworkManager and OpenVPN share resolved for VPN-provided DNS.
  programs.openvpn3.enable = true;
  services.resolved.enable = true;
  networking.networkmanager.dns = "systemd-resolved";

  # Suspend only. The disk layout has no persistent swap for hibernation.
  systemd.sleep.settings.Sleep = {
    AllowHibernation = false;
    AllowSuspendThenHibernate = false;
    AllowHybridSleep = false;
  };

  system.stateVersion = "26.05";
}
