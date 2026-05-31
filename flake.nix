{
  description = "NixOS configuration for my hosts";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-26.05";
    nixpkgs-unstable.url = "github:NixOS/nixpkgs/nixos-unstable";
    # Pinned to the merge commit of nixpkgs#525449 (claude-code 2.1.154 -> 2.1.156).
    # Bump or remove once nixos-unstable catches up past 2.1.156.
    nixpkgs-claude-code.url = "github:NixOS/nixpkgs/b2b9231f548668621aed54158e7a7bf5a388c7b5";

    home-manager = {
      url = "github:nix-community/home-manager/release-26.05";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    niri-flake = {
      url = "github:sodiboo/niri-flake";
      inputs.nixpkgs.follows = "nixpkgs-unstable";
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

    # Pinned to the nixos-26.05 branch to match stable nixpkgs + home-manager.
    # Intentionally NOT following our nixpkgs: nixvim builds against its own
    # tested nixos-26.05 pin, which avoids the programs.nixvim.nixpkgs.source
    # warning (at the cost of a second, near-identical nixpkgs in the lock).
    nixvim = {
      url = "github:nix-community/nixvim/nixos-26.05";
    };
  };

  outputs = { self, nixpkgs, nixpkgs-unstable, nixpkgs-claude-code, home-manager, niri-flake, dms, dgop, danksearch, disko, ... }@inputs:
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
            dms.nixosModules.greeter
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
