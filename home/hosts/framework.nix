{ config, inputs, lib, pkgs, pkgs-unstable, ... }:
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
    ../programs/msp-wine.nix
    ../programs/slack.nix
  ];

  local.niri.keyboardLayout = "us,dk";
  local.niri.extraBinds = ''
    Mod+Alt+Space { switch-layout "next"; }
  '';

  home.packages = with pkgs; [
    powershell
    sops
    pulumi-bin
    terraform
    argocd
    pkgs-unstable.freelens-bin
    jetbrains.rider
    dotnet-sdk_10
    dbeaver-bin
    # TinyRDM's native Wayland backend renders a broken layout under niri.
    (symlinkJoin {
      name = "tiny-rdm-x11";
      paths = [ tiny-rdm ];
      nativeBuildInputs = [ makeWrapper ];
      postBuild = ''
        wrapProgram $out/bin/tiny-rdm --set GDK_BACKEND x11
      '';
    })
    charles
  ];

  home.sessionVariables.DOTNET_ROOT = "${pkgs.dotnet-sdk_10}/share/dotnet";

  # Install the integration; DMS Settings owns its toggle and bar placement.
  programs.dank-material-shell.plugins.dankscale = {
    enable = true;
    src = inputs.dms-dankscale;
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
