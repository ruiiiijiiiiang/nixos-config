{ lib, ... }:

{
  imports = [
    ./server.nix
    ./agent.nix
  ];

  options.custom.services.security.wazuh.version = lib.mkOption {
    type = lib.types.str;
    default = "4.14.4";
    description = "Wazuh version for server and agent.";
  };
}
