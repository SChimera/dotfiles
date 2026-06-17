{ pkgs, ... }:
{
  # Proton Drive CLI — `proton-drive` on PATH. Stores its session in the
  # gnome-keyring Secret Service (already provided by niri-flake, unlocked at
  # login via PAM). See pkgs/proton-drive-cli.nix for the nix-ld/libsecret notes.
  home.packages = [ (pkgs.callPackage ../../pkgs/proton-drive-cli.nix { }) ];
}
