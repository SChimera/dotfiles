{ pkgs, inputs, username, hostConfig, ... }:
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

  # Minimal AccountsService keyfile pointing at seb's icon. accounts-daemon
  # reports IconFile from this Icon= key (it does not scan the icons/ dir),
  # while the dms-greeter reads the icon file directly — so both the login
  # screen and the in-session shell resolve the same avatar.
  accountsUserFile = pkgs.writeText "accountsservice-${username}" ''
    [User]
    Icon=/var/lib/AccountsService/icons/${username}
  '';

  # seb's avatar, fetched from his GitHub profile and pinned by hash — kept out
  # of git as a fixed-output derivation rather than a committed binary. Update
  # the hash whenever the GitHub picture changes (a mismatch fails the build):
  #   nix store prefetch-file --name seb-avatar 'https://github.com/SChimera.png?size=512'
  avatarImage = pkgs.fetchurl {
    url = "https://github.com/SChimera.png?size=512";
    name = "seb-avatar";
    hash = "sha256-CjotV5UwkL6t4H+3EB7QCKZBmz7d4jnhveR43GOmW+c=";
  };
in
{
  imports = [
    # Copy here after running `nixos-generate-config` on the machine
    ./hardware-configuration.nix
    ../gaming.nix
  ];

  networking.hostName = "haven";

  time.timeZone = hostConfig.timezone or "Europe/Copenhagen";

  # niri-flake overlay — exposes pkgs.niri-{stable,unstable} and
  # pkgs.xwayland-satellite-{stable,unstable} built against this nixpkgs.
  nixpkgs.overlays = [ inputs.niri-flake.overlays.niri ];

  # Enable niri session — also adds it to displayManager.sessionPackages.
  # niri-flake.nixosModules.niri auto-injects homeModules.config into HM
  # sharedModules, so user-level config in home/programs/niri.nix still works.
  programs.niri.enable = true;
  # niri-unstable is required for the xwayland-satellite KDL block in home/programs/niri.nix.
  programs.niri.package = pkgs.niri-unstable;
  # DMS provides its own polkit agent; disable niri-flake's to avoid conflict.
  systemd.user.services.niri-flake-polkit.enable = false;

  # Bootloader — assumes UEFI. For legacy BIOS swap to grub.
  boot.loader.systemd-boot.enable = true;
  # Cap boot-menu entries. Generations are still GC'd by age (nix.gc in
  # common.nix); this just stops the menu filling with dozens of them.
  boot.loader.systemd-boot.configurationLimit = 20;
  boot.loader.efi.canTouchEfiVariables = true;

  # DankGreeter — syncs DMS theme into the login screen
  programs.dank-material-shell.greeter = {
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

  # AccountsService — lets the running DMS shell (Control Center, lock screen,
  # dash) resolve seb's profile picture over D-Bus. Without it only the greeter
  # shows an avatar (it reads the icon file directly; the in-session shell has
  # no file fallback and queries accounts-daemon).
  services.accounts-daemon.enable = true;

  # Seed seb's avatar (fetched GitHub pfp, see avatarImage above) on every
  # activation. The icon is world-readable so the `greeter` user can read it;
  # the keyfile stays root-only like the rest of /var/lib/AccountsService.
  # Declarative on purpose — re-asserted each rebuild, so it survives a reinstall
  # (changing the pic via DMS Settings would be overwritten on the next switch).
  system.activationScripts.sebAvatar.text = ''
    install -Dm644 ${avatarImage} /var/lib/AccountsService/icons/${username}
    install -Dm600 ${accountsUserFile} /var/lib/AccountsService/users/${username}
  '';

  # NVIDIA GPU (required for Wayland/niri)
  hardware.graphics.enable = true;
  services.xserver.videoDrivers = [ "nvidia" ];
  hardware.nvidia = {
    modesetting.enable = true;
    open = true;
    nvidiaSettings = true;
    powerManagement.enable = true;  # better suspend/resume on Wayland
  };

  users.users.${username} = {
    isNormalUser = true;
    extraGroups = [ "wheel" "networkmanager" "video" "audio" "input" ];
    shell = pkgs.fish;
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
