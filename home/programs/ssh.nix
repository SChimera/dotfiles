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
    # HM is deprecating the auto-populated default matchBlocks."*"; opt out and
    # supply our own wildcard block so addKeysToAgent applies cleanly.
    enableDefaultConfig = false;
    matchBlocks = {
      "*" = {
        addKeysToAgent = "yes";
        forwardAgent = false;
        compression = false;
        serverAliveInterval = 0;
        serverAliveCountMax = 3;
        hashKnownHosts = false;
        userKnownHostsFile = "~/.ssh/known_hosts";
        controlMaster = "no";
        controlPath = "~/.ssh/master-%r@%n:%p";
        controlPersist = "no";
      };
    } // lib.optionalAttrs (identityFile != null) {
      "github.com".identityFile = identityFile;
      # "gitlab.com".identityFile = identityFile;
    };
  };

  home.activation.createWorkDirs = lib.hm.dag.entryAfter [ "writeBoundary" ] (
    lib.concatMapStrings (dir: "mkdir -p \"$HOME/${dir}\"\n") workDirs
  );
}
