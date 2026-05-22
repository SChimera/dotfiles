{ pkgs, ... }:
{
  programs.fish = {
    enable = true;
    shellAliases = {
      ll = "ls -la";
      ".." = "cd ..";
      nixswitch = "sudo nixos-rebuild switch --flake ~/.dotfiles#$(hostname)";
      homeswitch = "home-manager switch --flake ~/.dotfiles";
    };
  };

  programs.starship = {
    enable = true;
    enableFishIntegration = true;
  };
}
