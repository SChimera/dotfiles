{ pkgs, ... }:
{
  programs.zed-editor = {
    enable = true;
    # The Zed Nix extension doesn't ship/download language servers; it expects
    # nil/nixd on PATH. extraPackages adds them to Zed's wrapper only.
    extraPackages = with pkgs; [
      nil
      nixd
      nixfmt-rfc-style # nixd's formatter (configured in Zed settings)
    ];
    # Evaluating Zed: keep settings/keymaps editable from the in-app UI.
    # Once settled, copy settings.json into userSettings and drop these.
    mutableUserSettings = true;
    mutableUserKeymaps = true;
  };
}
