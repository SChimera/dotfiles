{
  description = "NixOS configuration for my hosts";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-26.05";
    nixpkgs-unstable.url = "github:NixOS/nixpkgs/nixos-unstable";
    # Dedicated input so claude-code tracks nixpkgs' newest packaged version
    # without dragging the unstable desktop stack. `nix flake update nixpkgs-claude-code` to bump.
    # master, not nixos-unstable: the update bot lands claude-code bumps here first,
    # channel promotion lags days behind.
    nixpkgs-claude-code.url = "github:NixOS/nixpkgs/master";

    home-manager = {
      url = "github:nix-community/home-manager/release-26.05";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    niri-flake = {
      url = "github:sodiboo/niri-flake";
      inputs.nixpkgs.follows = "nixpkgs-unstable";
    };

    # Track the default branch, not /stable: the stable branch is frozen
    # (Apr 2026) and still ships a greeter niri config with the removed
    # `keep-max-bpc-unchanged` debug node, which breaks under niri-unstable.
    # Default branch keeps pace with the bleeding-edge niri we run.
    dms = {
      url = "github:AvengeMedia/DankMaterialShell";
      inputs.nixpkgs.follows = "nixpkgs-unstable";
    };

    # Greeter split out of DankMaterialShell (2026-07-24): DMS dropped its
    # nixosModules.greeter; the login screen now lives here as its own flake.
    # Provides programs.dms-greeter (was programs.dank-material-shell.greeter).
    dank-greeter = {
      url = "github:AvengeMedia/dank-greeter";
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

    # Pinned to the nixos-26.05 branch to match stable nixpkgs + home-manager.
    # Intentionally NOT following our nixpkgs: nixvim builds against its own
    # tested nixos-26.05 pin, which avoids the programs.nixvim.nixpkgs.source
    # warning (at the cost of a second, near-identical nixpkgs in the lock).
    nixvim = {
      url = "github:nix-community/nixvim/nixos-26.05";
    };

    # Nix packaging of sgtaziz/lian-li-linux (fan/RGB control for the SL V2).
    lian-li-linux = {
      url = "github:SChimera/lian-li-linux-nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs = { self, nixpkgs, nixpkgs-unstable, nixpkgs-claude-code, home-manager, niri-flake, dms, danksearch, disko, ... }@inputs:
    let
      local = if builtins.pathExists ./local.nix then import ./local.nix else {};

      mkHost = { hostname, username, hostConfig ? {}, system ? "x86_64-linux" }:
        nixpkgs.lib.nixosSystem {
          inherit system;
          specialArgs = {
            inherit inputs hostname username hostConfig;
            pkgs-unstable = import nixpkgs-unstable { inherit system; config.allowUnfree = true; };
            pkgs-claude-code = import nixpkgs-claude-code { inherit system; config.allowUnfree = true; };
          };
          modules = [
            ./nixos/common.nix
            ./nixos/hosts/${hostname}.nix
            ./nixos/hosts/${hostname}-disko.nix
            disko.nixosModules.disko
            niri-flake.nixosModules.niri
            inputs.dank-greeter.nixosModules.dank-greeter
            inputs.lian-li-linux.nixosModules.default
            { services.lianli.enable = true; }
            home-manager.nixosModules.home-manager
            {
              home-manager.useGlobalPkgs = true;
              home-manager.useUserPackages = true;
              home-manager.extraSpecialArgs = {
                inherit inputs username hostConfig;
                pkgs-unstable = import nixpkgs-unstable { inherit system; config.allowUnfree = true; };
                pkgs-claude-code = import nixpkgs-claude-code { inherit system; config.allowUnfree = true; };
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
