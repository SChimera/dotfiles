# Keys and TPM enrollment are local to the laptop. See INSTALL.md.
{ config, inputs, lib, pkgs, ... }:
{
  imports = [ inputs.lanzaboote.nixosModules.lanzaboote ];

  boot.loader.systemd-boot.enable = lib.mkIf config.boot.lanzaboote.enable (lib.mkForce false);
  boot.loader.systemd-boot.editor = false;
  boot.lanzaboote = {
    enable = true;
    pkiBundle = "/var/lib/sbctl";
    # systemd-pcrlock supports at most eight boot variants.
    configurationLimit = 8;
    measuredBoot = {
      enable = true;
      # Bind unlocking to firmware, the signed boot chain, and Secure Boot.
      # Lanzaboote updates the boot measurements when generations change.
      pcrs = [ 0 4 7 ];
    };
  };

  boot.initrd.systemd.enable = true;
  boot.initrd.systemd.tpm2.enable = true;
  boot.initrd.luks.devices.cryptroot.crypttabExtraOpts = [ "tpm2-device=auto" ];
  security.tpm2.enable = true;
  environment.systemPackages = [ pkgs.sbctl ];
}
