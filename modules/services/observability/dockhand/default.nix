{ config, lib, helpers,...}:
let
  inherit (helpers) mkOciUser;
  cfg = config.custom.services.observability.dockhand;
in
{
  imports = [
    ./server.nix
    ./agent.nix
  ];

  users = lib.mkIf (cfg.server.enable || cfg.agent.enable)
    (mkOciUser "dockhand");
}
