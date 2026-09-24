{ hostConfig, lib, pkgs, ... }:
let
  # Every host declares its identity; a missing entry must not inherit Haven's key.
  inherit (hostConfig.git) name email;
  signingKey = hostConfig.git.signingKey or null;
  workEmail = "sec@moviestarplanet.com";
in
{
  programs.git = {
    enable = true;
    # Work repos get the work identity by remote URL.
    includes = map (url: {
      condition = "hasconfig:remote.*.url:${url}";
      contents.user.email = workEmail;
    }) [
      "git@github.com:moviestarplanet/**"
      "https://github.com/moviestarplanet/**"
    ];
    settings = {
      alias = {
        oops = "commit --amend --no-edit";
        s = "status";
      };
      user = {
        inherit name email;
      } // lib.optionalAttrs (signingKey != null) { signingKey = signingKey; };
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
    };
  };

  # Read the public key so activation also works with passphrase-protected keys.
  # ssh-keygen creates this .pub file alongside the private key at first login.
  home.activation.gitAllowedSigners = lib.mkIf (signingKey != null)
    (lib.hm.dag.entryAfter [ "writeBoundary" ] ''
      key="${signingKey}"
      key="''${key/#\~/$HOME}"
      if [ -f "$key.pub" ]; then
        install -d -m 700 "$HOME/.config/git"
        pub="$(cat "$key.pub")"
        printf '%s %s\n' "${email},${workEmail}" "$pub" > "$HOME/.config/git/allowed_signers"
      fi
    '');
}
