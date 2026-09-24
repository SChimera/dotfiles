{ pkgs, inputs, username, ... }:
let
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
