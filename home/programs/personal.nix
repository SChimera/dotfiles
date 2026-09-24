{ pkgs-unstable, ... }:
{
  home.packages = [
    # Discord's host and module downloads pinned from its official update manifest.
    (pkgs-unstable.discord.override {
      source = builtins.fromJSON (builtins.readFile ../../pkgs/discord-source.json);
    })
  ];
}
