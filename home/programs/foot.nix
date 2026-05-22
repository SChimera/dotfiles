{ ... }:
{
  programs.foot = {
    enable = true;
    settings = {
      main = {
        font = "JetBrainsMono Nerd Font:size=11";
        pad = "8x8";
      };
      mouse.hide-when-typing = "yes";
      colors = {
        alpha = "0.95";
      };
    };
  };
}
