{ pkgs, ... }:
{
  programs.fish = {
    enable = true;
    shellAliases = {
      ls = "eza";
      ll = "eza -la";
      la = "eza -a";
      lt = "eza --tree --level=2";
      ".." = "cd ..";
      "..." = "cd ../..";
      nixswitch = "sudo nixos-rebuild switch --flake ~/code/personal/dotfiles#(hostname)";
      nixup = "nix flake update --flake ~/code/personal/dotfiles";
      nixgc = "sudo nix-collect-garbage -d";
      cc = "claude --dangerously-skip-permissions";
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
