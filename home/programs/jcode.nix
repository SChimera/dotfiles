# jcode TUI coding agent (1jehuang/jcode), packaged by grigio's flake.
# Built from the pinned upstream source — grigio's binary cache and signing
# key are deliberately NOT trusted (see the flake input comment).
{ inputs, pkgs, ... }:
{
  home.packages = [ inputs.jcode.packages.${pkgs.stdenv.hostPlatform.system}.default ];

  home.sessionVariables = {
    # Telemetry is opt-out (upstream TELEMETRY.md); this short-circuits all
    # telemetry network calls.
    JCODE_NO_TELEMETRY = "1";
    # The self-updater can't write to the read-only store; skip the check.
    JCODE_NO_AUTO_UPDATE = "1";
  };
}
