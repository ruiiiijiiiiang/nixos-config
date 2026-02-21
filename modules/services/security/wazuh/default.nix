{ lib, ... }:

{
  imports = [
    ./server.nix
    ./agent.nix
  ];

  options.custom.services.security.wazuh.version = lib.mkOption {
    type = lib.types.str;
    default = "4.14.2";
    description = "Wazuh version used by both server and agent.";
  };
}
