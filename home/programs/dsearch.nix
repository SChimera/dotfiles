{ inputs, pkgs-unstable, ... }:
let
  # Upstream's flake ships a stale vendorHash as of danksearch 0.3.1 (db1c8f8,
  # 2026-05-21). Rebuild from the same source with the hash Nix actually
  # computes. Drop this whole override once upstream bumps vendorHash.
  dsearchPkg = pkgs-unstable.buildGoModule {
    pname = "dsearch";
    version = "0.3.1";
    src = inputs.danksearch;
    vendorHash = "sha256-scvZWbMHAhpYWCU0xZK1E6h6sAkoXegqI1iYS44fcCg=";
    subPackages = [ "cmd/dsearch" ];
    ldflags = [ "-s" "-w" "-X main.Version=0.3.1" ];
    meta.mainProgram = "dsearch";
  };
in
{
  imports = [
    inputs.danksearch.homeModules.dsearch
  ];

  programs.dsearch = {
    enable = true;
    package = dsearchPkg;

    config.index_paths = [
      {
        path = "~";
        max_depth = 4;
        exclude_hidden = true;
        extract_exif = false;
        merge_default_exclude_dirs = true;
      }
      {
        path = "~/code";
        max_depth = 0;
        exclude_hidden = true;
        extract_exif = false;
        merge_default_exclude_dirs = true;
        exclude_dirs = [ ".git" ".direnv" "result" "target" ];
      }
      {
        path = "~/Downloads";
        max_depth = 2;
        exclude_hidden = true;
        extract_exif = true;
        merge_default_exclude_dirs = true;
      }
    ];
  };
}
