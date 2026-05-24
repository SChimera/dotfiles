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

  # framework = {
  #   username = "youruser";
  #   hostConfig = {
  #     timezone = "Europe/London";
  #     git = {
  #       name = "Your Name";
  #       email = "you@work.com";
  #       signingKey = "~/.ssh/id_ed25519_framework";
  #     };
  #     ssh.identityFile = "~/.ssh/id_ed25519_framework";
  #     workDirs = [ "code/work" "code/personal" ];
  #   };
  # };
}
