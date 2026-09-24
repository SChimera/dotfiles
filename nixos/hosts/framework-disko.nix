# Declarative disk layout for the framework laptop, applied by `disko`.
#
# Single NVMe: ESP + LUKS2-encrypted btrfs. The ESP remains unencrypted.
# Supply the temporary passphrase file during installation, see INSTALL.md.
#
# Verified on the laptop: WD_BLACK SN7100 4TB, serial 25244L401612.
# Suspend only: shared zram provides compressed swap in RAM.
#
# WARNING: disko WIPES the disk listed below.
{ ... }:
let
  # zstd level 3 — strong compression, modest CPU cost.
  btrfsOpts = [ "compress=zstd:3" "noatime" "discard=async" ];
in
{
  disko.devices.disk.main = {
    type = "disk";
    device = "/dev/disk/by-id/nvme-WD_BLACK_SN7100_4TB_25244L401612";
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
        luks = {
          size = "100%";
          content = {
            type = "luks";
            name = "cryptroot";
            # Used only to format/unlock during install, never included in the
            # Nix store or initrd. The passphrase remains the recovery method
            # after TPM enrollment.
            passwordFile = "/tmp/framework-luks-password";
            # SSD TRIM through the LUKS layer (small information leak about
            # free space, standard trade-off for keeping the drive healthy).
            settings.allowDiscards = true;
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
  };
}
