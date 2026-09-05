{ pkgs, config, ... }:
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
      nixswitch = "nh os switch";
      nixup = "nix flake update --flake ~/code/personal/dotfiles";
      nixgc = "sudo nix-collect-garbage -d";
      cc = "claude --dangerously-skip-permissions";
      cx = "codex --yolo";
    };
  };

  # nh: nicer nixos-rebuild — prints a package diff on every switch and drives
  # builds through nom (readable tree instead of a flat log). flake path is set
  # once here; `nh os switch` auto-detects the hostname → nixosConfigurations.<host>,
  # so this same config works unchanged on a second host.
  programs.nh = {
    enable = true;
    flake = "${config.home.homeDirectory}/code/personal/dotfiles";
  };

  programs.starship = {
    enable = true;
    settings = {
      # `go version` (and other version probes) can exceed the 500ms default
      # on a cold Nix-store page-in when first entering a repo.
      command_timeout = 2000;
    };
  };

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
