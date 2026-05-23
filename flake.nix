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
    };

    dms = {
      url = "github:AvengeMedia/DankMaterialShell/stable";
      inputs.nixpkgs.follows = "nixpkgs-unstable";
    };

    dgop = {
      url = "github:AvengeMedia/dgop";
      inputs.nixpkgs.follows = "nixpkgs-unstable";
    };
  };

  outputs = { self, nixpkgs, nixpkgs-unstable, home-manager, niri-flake, dms, dgop, ... }@inputs:
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
            niri-flake.nixosModules.niri
            dms.nixosModules.greeter
            home-manager.nixosModules.home-manager
            {
              home-manager.useGlobalPkgs = true;
              home-manager.useUserPackages = true;
              home-manager.extraSpecialArgs = { inherit inputs username hostConfig; };
              home-manager.users.${username} = import ./home/hosts/${hostname}.nix;
            }
          ];
        };
    in {
      formatter."x86_64-linux" = nixpkgs.legacyPackages."x86_64-linux".alejandra;

      nixosConfigurations = {
        haven = mkHost {
          hostname = "haven";
          username = (local.haven or {}).username or "youruser";
          hostConfig = (local.haven or {}).hostConfig or {};
        };
      };
    };
}
