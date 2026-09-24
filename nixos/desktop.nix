# Graphical session shared by Haven and Framework.
{ pkgs, inputs, username, ... }:
let
  # The greeter launches quickshell directly via niri's spawn-at-startup,
  # bypassing the `dms` wrapper that (in a normal desktop session) injects the
  # qtimageformats Qt plugin into QT_PLUGIN_PATH. Without that plugin quickshell
  # can't decode webp, so a webp wallpaper renders as nothing and the greeter
  # falls back to a black background — the QML login UI itself still draws fine.
  # Wrap quickshell so the webp image-format plugin is always on its
  # QT_PLUGIN_PATH (matches quickshell's qtbase 6.11; --prefix preserves the
  # paths quickshell's own wrapper prepends). Desktop sessions are unaffected.
  greeterQuickshell = pkgs.symlinkJoin {
    name = "quickshell-greeter-webp";
    paths = [ pkgs.quickshell ];
    nativeBuildInputs = [ pkgs.makeWrapper ];
    postBuild = ''
      for bin in "$out"/bin/*; do
        wrapProgram "$bin" \
          --prefix QT_PLUGIN_PATH : ${pkgs.kdePackages.qtimageformats}/lib/qt-6/plugins
      done
    '';
  };
in
{
  imports = [
    inputs.niri-flake.nixosModules.niri
    inputs.dank-greeter.nixosModules.dank-greeter
  ];

  # Enable niri session — also adds it to displayManager.sessionPackages.
  # niri-flake.nixosModules.niri auto-injects homeModules.config into HM
  # sharedModules, so user-level config in home/programs/niri.nix still works.
  programs.niri.enable = true;
  # niri release from nixpkgs-unstable: Hydra-built, always on cache.nixos.org.
  # niri-flake's overlay built git niri against this system's nixpkgs — a
  # derivation no cache has, so every stable-nixpkgs bump recompiled niri and
  # its whole Rust dep chain (~1150 drvs). The 26.04 release supports the
  # xwayland-satellite KDL block, and dank-greeter picks this package up
  # automatically via programs.niri.package.
  programs.niri.package = inputs.nixpkgs-unstable.legacyPackages.${pkgs.stdenv.hostPlatform.system}.niri;
  # DMS provides its own polkit agent; disable niri-flake's to avoid conflict.
  systemd.user.services.niri-flake-polkit.enable = false;

  # Bootloader — assumes UEFI. For legacy BIOS swap to grub.
  boot.loader.systemd-boot.enable = true;
  # Cap boot-menu entries. Generations are still GC'd by age (nix.gc in
  # common.nix); this just stops the menu filling with dozens of them.
  boot.loader.systemd-boot.configurationLimit = 20;
  boot.loader.efi.canTouchEfiVariables = true;

  # DankGreeter — syncs DMS theme into the login screen. Split out of DMS into
  # the standalone dank-greeter flake (2026-07-24); namespace is now dms-greeter.
  programs.dms-greeter = {
    enable = true;
    compositor.name = "niri";
    configHome = "/home/${username}";
    # webp-capable quickshell so the wallpaper renders (see greeterQuickshell above)
    quickshell.package = greeterQuickshell;
    logs = {
      save = true;
      path = "/tmp/dms-greeter.log";
    };
  };

  hardware.graphics.enable = true;
}
