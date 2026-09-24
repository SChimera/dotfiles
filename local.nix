# Per-host config: username, timezone, git identity, ssh key paths.
{
  haven = {
    username = "seb";
    hostConfig = {
      timezone = "Europe/Copenhagen"; # optional — defaults to Europe/Copenhagen
      git = {
        name = "Sebastian Chimera";
        email = "schimera@schimera.dev";
        signingKey = "~/.ssh/id_ed25519_haven";
      };
      ssh.identityFile = "~/.ssh/id_ed25519_haven";
      workDirs = [ "code/personal" ];
    };
  };

  framework = {
    username = "seb";
    hostConfig = {
      timezone = "Europe/Copenhagen";
      git = {
        name = "Sebastian Chimera";
        email = "sec@moviestarplanet.com";
        signingKey = "~/.ssh/id_ed25519";
      };
      ssh.identityFile = "~/.ssh/id_ed25519";
      workDirs = [ "code/work" "code/personal" ];
    };
  };
}
