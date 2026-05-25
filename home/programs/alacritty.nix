{ ... }:
{
  programs.alacritty = {
    enable = true;
    settings = {
      # DMS's matugen writes ~/.config/alacritty/dank-theme.toml on theme
      # change; alacritty live-reloads when imported files change (since 0.13).
      general.import = [ "~/.config/alacritty/dank-theme.toml" ];

      window = {
        padding = { x = 8; y = 8; };
        opacity = 0.95;
      };

      font = {
        normal.family = "JetBrainsMono Nerd Font";
        size = 11;
      };

      mouse.hide_when_typing = true;
    };
  };
}
