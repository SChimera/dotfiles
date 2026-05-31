{ hostConfig, lib, ... }:
let
  identityFile = hostConfig.ssh.identityFile or null;
  workDirs = hostConfig.workDirs or [ ];
in
{
  programs.ssh = {
    enable = true;
    # Generate per-machine key with:
    # ssh-keygen -t ed25519 -C "hostname" -f ~/.ssh/id_ed25519_<hostname>
    # HM deprecated the auto-populated default block; opt out and supply our own
    # wildcard block (OpenSSH directive names) so AddKeysToAgent applies cleanly.
    enableDefaultConfig = false;
    settings = {
      "*" = {
        AddKeysToAgent = "yes";
        ForwardAgent = false;
        Compression = false;
        ServerAliveInterval = 0;
        ServerAliveCountMax = 3;
        HashKnownHosts = true;
        UserKnownHostsFile = "~/.ssh/known_hosts";
        ControlMaster = "auto";
        ControlPath = "~/.ssh/master-%r@%n:%p";
        ControlPersist = "10m";
      };
    } // lib.optionalAttrs (identityFile != null) {
      "github.com".IdentityFile = identityFile;
      # "gitlab.com".IdentityFile = identityFile;
    };
  };

  home.activation.createWorkDirs = lib.hm.dag.entryAfter [ "writeBoundary" ] (
    lib.concatMapStrings (dir: "mkdir -p \"$HOME/${dir}\"\n") workDirs
  );
}
