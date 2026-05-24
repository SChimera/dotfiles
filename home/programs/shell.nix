{ pkgs, ... }:
{
  programs.fish = {
    enable = true;
    shellAliases = {
      ls = "eza";
      ll = "eza -la";
      ".." = "cd ..";
      nixswitch = "sudo nixos-rebuild switch --flake ~/.dotfiles#(hostname)";
      homeswitch = "home-manager switch --flake ~/.dotfiles";
    };
  };

  programs.starship.enable = true;

  programs.zoxide = {
    enable = true;
    options = [ "--cmd" "cd" ];
  };

  programs.fzf.enable = true;

  programs.eza = {
    enable = true;
    git = true;
    icons = "auto";
    extraOptions = [ "--group-directories-first" ];
  };

  programs.bat = {
    enable = true;
    config.theme = "ansi";
  };

  programs.direnv = {
    enable = true;
    nix-direnv.enable = true;
  };
}
