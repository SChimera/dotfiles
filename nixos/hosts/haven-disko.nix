# Declarative disk layout for haven, applied by `disko`.
#
# DISK ASSIGNMENT
#   Disk 0 (Crucial T705 Gen5, 2 TB) → ESP + / + /nix + /home  (main)
#   Disk 1 (Samsung 990 PRO,   2 TB) → /games                   (games)
#   Disk 2 (Samsung 990 PRO,   2 TB) → /data + VMs + /backups   (data)
#
# Fill in REAL serials on the live ISO. To find them:
#   ls -l /dev/disk/by-id/ | grep nvme | grep -v part
# Disambiguate the two 990 PROs by serial — one was "Games2" (empty) in
# Windows; pick that one for /games or /data, your call.
#
# WARNING: disko WIPES every disk listed below.
{ ... }:
let
  # zstd level 3 — strong compression, negligible CPU on the 9800X3D.
  btrfsOpts        = [ "compress=zstd:3" "noatime" "discard=async" ];
  # zstd level 1 — favour read latency over ratio. Game assets compress poorly.
  btrfsGamesOpts   = [ "compress=zstd:1" "noatime" "discard=async" ];
  # nodatacow: VM disk images do small random writes that fragment CoW badly.
  btrfsNoCowOpts   = [ "noatime" "discard=async" "nodatacow" ];
  # Surface the mount in Nautilus's sidebar (gvfs hides fstab mounts by default).
  showInFiles      = [ "x-gvfs-show" ];
in
{
  disko.devices.disk = {
    # =====================================================================
    # Disk 0 — Crucial T705 (Gen5): boot + OS + Nix store + /home
    # =====================================================================
    main = {
      type = "disk";
      device = "/dev/disk/by-id/nvme-CT2000T705SSD3_2505E9A44AFF";
      content = {
        type = "gpt";
        partitions = {
          ESP = {
            size = "1G";
            type = "EF00";
            content = {
              type = "filesystem";
              format = "vfat";
              mountpoint = "/boot";
              mountOptions = [ "umask=0077" "fmask=0077" "dmask=0077" ];
            };
          };
          root = {
            size = "100%";
            content = {
              type = "btrfs";
              extraArgs = [ "-f" "-L" "nixos" ];
              subvolumes = {
                "@"          = { mountpoint = "/";           mountOptions = btrfsOpts; };
                "@nix"       = { mountpoint = "/nix";        mountOptions = btrfsOpts; };
                "@home"      = { mountpoint = "/home";       mountOptions = btrfsOpts; };
                "@snapshots" = { mountpoint = "/.snapshots"; mountOptions = btrfsOpts; };
              };
            };
          };
        };
      };
    };

    # =====================================================================
    # Disk 1 — Samsung 990 PRO: Steam / Lutris / Bottles libraries
    # =====================================================================
    games = {
      type = "disk";
      device = "/dev/disk/by-id/nvme-Samsung_SSD_990_PRO_2TB_S6Z2NJ0TA20804Y";
      content = {
        type = "gpt";
        partitions.games = {
          size = "100%";
          content = {
            type = "btrfs";
            extraArgs = [ "-f" "-L" "games" ];
            subvolumes = {
              "@games"           = { mountpoint = "/games";           mountOptions = btrfsGamesOpts ++ showInFiles; };
              "@games-snapshots" = { mountpoint = "/games/.snapshots"; mountOptions = btrfsGamesOpts; };
            };
          };
        };
      };
    };

    # =====================================================================
    # Disk 2 — Samsung 990 PRO: bulk data + VMs + on-disk backups
    # =====================================================================
    data = {
      type = "disk";
      device = "/dev/disk/by-id/nvme-Samsung_SSD_990_PRO_2TB_S6Z2NJ0TA20813V";
      content = {
        type = "gpt";
        partitions.data = {
          size = "100%";
          content = {
            type = "btrfs";
            extraArgs = [ "-f" "-L" "data" ];
            subvolumes = {
              "@data"    = { mountpoint = "/data";            mountOptions = btrfsOpts ++ showInFiles; };
              "@vms"     = { mountpoint = "/var/lib/libvirt"; mountOptions = btrfsNoCowOpts; };
              "@backups" = { mountpoint = "/backups";         mountOptions = btrfsOpts ++ showInFiles; };
            };
          };
        };
      };
    };
  };
}
