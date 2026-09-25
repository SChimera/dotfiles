{ config, lib, pkgs, ... }:
let
  initialDmsSettings = pkgs.writeText "framework-dms-settings.json" (builtins.toJSON {
    lockBeforeSuspend = true;
    acLockTimeout = 300;
    batteryLockTimeout = 300;
  });
in
{
  imports = [
    ../common.nix
    ../programs/dms-openvpn3.nix
  ];

  home.packages = with pkgs; [
    slack
    powershell
    sops
    pulumi-bin
    terraform
    argocd
    freelens-bin
    jetbrains.rider
    dotnet-sdk_10
    dbeaver-bin
    tiny-rdm
    charles
  ];

  home.sessionVariables.DOTNET_ROOT = "${pkgs.dotnet-sdk_10}/share/dotnet";

  # Refresh the domain file with devops-openvpn/scripts/export-dns-domains.py.
  xdg.configFile."dms-openvpn3/dns.json".text = builtins.toJSON {
    profiles.framework = {
      enabled = true;
      file = "${config.xdg.configHome}/dms-openvpn3/application-domains.json";
    };
  };

  # Seed first-login defaults without making DMS's settings file read-only.
  # Later changes made in DMS Settings survive rebuilds.
  home.activation.seedDmsSettings = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
    settingsFile="${config.xdg.configHome}/DankMaterialShell/settings.json"
    if [ ! -e "$settingsFile" ] && [ ! -L "$settingsFile" ]; then
      run ${pkgs.coreutils}/bin/install -Dm600 ${initialDmsSettings} "$settingsFile"
    fi
  '';

  home.stateVersion = "26.05";
}
