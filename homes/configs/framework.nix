{ consts, ... }:
let
  inherit (consts) ports endpoints;
in
{
  imports = [
    ../modules/files
  ];

  programs.ssh = {
    enable = true;
    enableDefaultConfig = false;
    matchBlocks = {
      "forgejo" = {
        hostname = endpoints.private-repo;
        user = "git";
        port = ports.forgejo.ssh;
      };
      "*" = {
        identityFile = "~/.ssh/id_ed25519";
      };
    };
  };

  custom.home = {
    dotfiles = {
      enable = true;
      role = "workstation";
      host = "framework";
    };
  };
}
