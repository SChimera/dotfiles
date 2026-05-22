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
    addKeysToAgent = "yes";
    matchBlocks = lib.optionalAttrs (identityFile != null) {
      "github.com".identityFile = identityFile;
      # "gitlab.com".identityFile = identityFile;
    };
  };

  home.activation.createWorkDirs = lib.hm.dag.entryAfter [ "writeBoundary" ] (
    lib.concatMapStrings (dir: "mkdir -p \"$HOME/${dir}\"\n") workDirs
  );
}
