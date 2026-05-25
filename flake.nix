{
  description = "NixOS configuration for my hosts";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-25.11";
    nixpkgs-unstable.url = "github:NixOS/nixpkgs/nixos-unstable";

    home-manager = {
      url = "github:nix-community/home-manager/release-25.11";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    niri-flake = {
      url = "github:sodiboo/niri-flake";
      inputs.nixpkgs.follows = "nixpkgs-unstable";
      # Pin xwayland-satellite back one commit to work around upstream regression
      # that breaks Steam top-bar hover dropdowns under Niri.
      # See: https://github.com/Supreeeme/xwayland-satellite/issues/435
      # Remove this override once the regression is fixed upstream.
      inputs.xwayland-satellite-unstable = {
        url = "github:Supreeeme/xwayland-satellite/a879e5e0896a326adc79c474bf457b8b99011027";
        flake = false;
      };
    };

    dms = {
      url = "github:AvengeMedia/DankMaterialShell/stable";
      inputs.nixpkgs.follows = "nixpkgs-unstable";
    };

    dgop = {
      url = "github:AvengeMedia/dgop";
      inputs.nixpkgs.follows = "nixpkgs-unstable";
    };

    danksearch = {
      url = "github:AvengeMedia/danksearch";
      inputs.nixpkgs.follows = "nixpkgs-unstable";
    };

    disko = {
      url = "github:nix-community/disko";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs = { self, nixpkgs, nixpkgs-unstable, home-manager, niri-flake, dms, dgop, danksearch, disko, ... }@inputs:
    let
      local = if builtins.pathExists ./local.nix then import ./local.nix else {};

      mkHost = { hostname, username, hostConfig ? {}, system ? "x86_64-linux" }:
        nixpkgs.lib.nixosSystem {
          inherit system;
          specialArgs = {
            inherit inputs hostname username hostConfig;
            pkgs-unstable = nixpkgs-unstable.legacyPackages.${system};
          };
          modules = [
            ./nixos/common.nix
            ./nixos/hosts/${hostname}.nix
            ./nixos/hosts/${hostname}-disko.nix
            disko.nixosModules.disko
            niri-flake.nixosModules.niri
            dms.nixosModules.greeter
            home-manager.nixosModules.home-manager
            {
              home-manager.useGlobalPkgs = true;
              home-manager.useUserPackages = true;
              home-manager.extraSpecialArgs = {
                inherit inputs username hostConfig;
                pkgs-unstable = nixpkgs-unstable.legacyPackages.${system};
              };
              # niri-flake.nixosModules.niri auto-injects homeModules.config into
              # sharedModules. Do not add homeModules.niri here — it re-imports
              # homeModules.config and duplicates the programs.niri.package option.
              home-manager.users.${username} = import ./home/hosts/${hostname}.nix;
            }
          ];
        };
    in {
      formatter."x86_64-linux" = nixpkgs.legacyPackages."x86_64-linux".alejandra;

      nixosConfigurations = {
        haven = mkHost {
          hostname = "haven";
          username = (local.haven or {}).username or "seb";
          hostConfig = (local.haven or {}).hostConfig or {};
        };
      };

      # `nix flake check` builds each host's toplevel so CI / pre-push catches
      # eval errors and broken modules without a full nixos-rebuild.
      checks."x86_64-linux" = builtins.mapAttrs
        (_: cfg: cfg.config.system.build.toplevel)
        self.nixosConfigurations;
    };
}
