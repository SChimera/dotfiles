{ hostConfig, lib, pkgs, ... }:
let
  signingKey = hostConfig.git.signingKey or null;
  email = hostConfig.git.email or "you@example.com";
in
{
  programs.git = {
    enable = true;
    aliases = {
      oops = "commit --amend --no-edit";
      s = "status";
    };
    settings = {
      user.name = hostConfig.git.name or "Your Name";
      user.email = email;
      init.defaultBranch = "main";
      pull.rebase = true;
      push.autoSetupRemote = true;
      rebase.autosquash = true;
      rebase.autoStash = true;
      help.autocorrect = 1;
      core.editor = "code --wait";
      core.pager = "delta";
      gpg.format = "ssh";
      commit.gpgsign = signingKey != null;
      "gpg \"ssh\"".allowedSignersFile = "~/.config/git/allowed_signers";
    } // (if signingKey != null then { user.signingKey = signingKey; } else {});
  };

  # Derive allowed_signers from the configured private key so commit
  # verification works out of the box. Skipped when no signing key is set.
  home.activation.gitAllowedSigners = lib.mkIf (signingKey != null)
    (lib.hm.dag.entryAfter [ "writeBoundary" ] ''
      key="${signingKey}"
      key="''${key/#\~/$HOME}"
      if [ -f "$key" ]; then
        install -d -m 700 "$HOME/.config/git"
        pub="$(${pkgs.openssh}/bin/ssh-keygen -y -f "$key")"
        printf '%s %s\n' "${email}" "$pub" > "$HOME/.config/git/allowed_signers"
      fi
    '');
}
