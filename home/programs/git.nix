{ hostConfig, ... }:
let
  signingKey = hostConfig.git.signingKey or null;
in
{
  programs.git = {
    enable = true;
    settings = {
      user.name = hostConfig.git.name or "Your Name";
      user.email = hostConfig.git.email or "you@example.com";
      init.defaultBranch = "main";
      pull.rebase = true;
      core.editor = "nvim";
      gpg.format = "ssh";
      commit.gpgsign = signingKey != null;
      "gpg \"ssh\"".allowedSignersFile = "~/.config/git/allowed_signers";
    } // (if signingKey != null then { user.signingKey = signingKey; } else {});
  };
}
