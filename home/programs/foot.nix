{ ... }:
{
  programs.foot.enable = true;

  # Written directly instead of via programs.foot.settings so we can put
  # `include=` at the top level — pkgs.formats.ini only emits section bodies.
  # DMS writes the matugen palette to ~/.config/foot/dank-colors.ini as a
  # [colors-dark] block; foot picks it up per the system color-scheme pref.
  xdg.configFile."foot/foot.ini".text = ''
    include=~/.config/foot/dank-colors.ini

    [main]
    font=JetBrainsMono Nerd Font:size=11
    pad=8x8

    [mouse]
    hide-when-typing=yes

    [colors]
    alpha=0.95
  '';
}
