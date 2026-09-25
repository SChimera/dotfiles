# Framework Laptop 13 Pro, Intel Core Ultra X7 358H, 32 GB RAM.
{ inputs, username, ... }:
{
  imports = [
    inputs.nixos-hardware.nixosModules.framework-intel-core-ultra-series3
    ./framework-hardware.nix
    ./framework-secure-boot.nix
    ../desktop.nix
  ];

  networking.hostName = "framework";
  services.power-profiles-daemon.enable = true;
  # DMS reads battery charge and charging state through UPower.
  services.upower.enable = true;

  # OpenVPN 3 needs its D-Bus services as well as the command-line client.
  # Let NetworkManager and OpenVPN share resolved for VPN-provided DNS.
  programs.openvpn3.enable = true;
  services.resolved.enable = true;
  networking.networkmanager.dns = "systemd-resolved";

  # Allow the active local user to apply DMS VPN DNS routing on tun0.
  # This covers all processes of that user, not only the plugin.
  security.polkit.extraConfig = ''
    polkit.addRule(function(action, subject) {
      if (subject.user === ${builtins.toJSON username} &&
          subject.local && subject.active &&
          action.lookup("interface") === "tun0" &&
          (action.id === "org.freedesktop.resolve1.set-domains" ||
           action.id === "org.freedesktop.resolve1.set-default-route")) {
        return polkit.Result.YES;
      }
    });
  '';

  # Suspend only. The disk layout has no persistent swap for hibernation.
  systemd.sleep.settings.Sleep = {
    AllowHibernation = false;
    AllowSuspendThenHibernate = false;
    AllowHybridSleep = false;
  };

  system.stateVersion = "26.05";
}
